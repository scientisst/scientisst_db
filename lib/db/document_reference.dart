part of "../scientisst_db.dart";

const Map<String, Type> _parseType = {
  "num": num,
  "int": int,
  "double": double,
  "DateTime": DateTime,
  "List": List,
  "String": String,
};

class DocumentReference {
  String objectId;
  CollectionReference parent;
  String _filePath;
  String _collectionsPath;
  _MetadataReference _metadata;

  DocumentReference._({@required this.parent, @required String path}) {
    assert(path != null &&
        path.isNotEmpty &&
        !path.contains(".") &&
        !path.contains("/"));

    objectId = path;

    _filePath = ScientISSTdb._joinPaths(parent._documentsPath, path);
    _collectionsPath = ScientISSTdb._joinPaths(parent._collectionsPath, path);

    final String metadataPath =
        ScientISSTdb._joinPaths(parent._metadataPath, path);
    _metadata = _MetadataReference(parent: this, path: metadataPath);
  }

  Future<File> get _file async => await ScientISSTdb._getFile(_filePath);
  Future<Directory> get _collections async =>
      await ScientISSTdb._getDirectory(_collectionsPath);

  CollectionReference collection(String path) {
    assert(!path.contains("/") && !path.contains("."));
    return CollectionReference._(parent: this, path: path);
  }

  Future<List<String>> listCollections() async {
    final Directory collections = await _collections;
    try {
      return List<String>.from(
        collections.listSync().where((file) => file is Directory).map(
              (file) async => file.path.split("/").last,
            ),
      );
    } on FileSystemException catch (e) {
      if (e.osError.errorCode != 2)
        throw e; // if error is not "No such file or directory"
      else
        print("No such document or collection"); //TODO improve error throwing
      return null;
    }
  }

  Future<List<CollectionReference>> getCollections() async {
    final List<String> collections = await listCollections();
    if (collections == null) return null;
    return List<CollectionReference>.from(
      collections.map(
        (String path) async => CollectionReference._(parent: this, path: path),
      ),
    );
  }

  Future<void> set(Map<String, dynamic> data, {bool merge: false}) async {
    if (!(await _file).existsSync()) await _init();
    if (merge) {
      await update(data);
    } else {
      if (data == null || data.isEmpty) {
        await delete();
      } else {
        await _write(data);
      }
    }
  }

  Future<void> _write(Map<String, dynamic> data) async {
    await _metadata.setFieldTypes(data);
    await (await _file).writeAsString(
      jsonEncode(data, toEncodable: _myEncode),
    );
  }

  dynamic _myEncode(dynamic item) {
    if (item is DateTime) {
      return item.toIso8601String();
    } else if (item is List<DateTime>) {
      return List<dynamic>.from(
        item.map(
          (DateTime i) => i.toIso8601String(),
        ),
      );
    } else if (item is List) {
      return List<dynamic>.from(item);
    }
    return item;
  }

  Future<void> update(Map<String, dynamic> data) async {
    Map<String, dynamic> _data = await _read();
    _data.addAll(data);
    await _write(_data);
  }

  Future<void> _init() async {
    if (parent != null && parent.parent != null) await parent.parent._init();
    await _metadata.init();
    (await _collections).createSync(recursive: true);
    (await _file).createSync(recursive: true);
  }

  Future<void> delete() async {
    (await _file).deleteSync();
    (await _collections).deleteSync(recursive: true);
    await _metadata.delete();
    await parent?._deleteEmpty();
  }

  String get id => objectId;

  Future<Map<String, dynamic>> _read() async {
    try {
      final Map<String, String> fieldsType = (await _metadata.get()).fieldsType;
      return jsonDecode(
        (await _file).readAsStringSync(),
        reviver: fieldsType.isEmpty
            ? null
            : (key, value) {
                if (key is String) {
                  final String type = fieldsType[key];
                  if (value.runtimeType != _parseType[type] && type != "List") {
                    return _convertToType(
                      value,
                      type,
                    );
                  }
                }
                return value;
              },
      );
    } on FormatException catch (_) {
      return {};
    } on FileSystemException catch (e) {
      throw e;
    }
  }

  Future<DocumentSnapshot> get() async {
    final MetadataSnapshot metadata = await _metadata.get();
    return DocumentSnapshot(this, await _read(), metadata);
  }

  Stream<DocumentSnapshot> watch() async* {
    DocumentSnapshot doc = await get();
    yield doc;
    await for (WatchEvent _ in FileWatcher(await _absolutePath).events) {
      doc = await get();
      yield doc;
    }
  }

  static dynamic _convertToType(dynamic value, String type) {
    switch (type) {
      case "DateTime":
        return DateTime.parse(value);
      case "List<DateTime>":
        return List<DateTime>.from(
          (value as List<dynamic>).map(
            (dynamic item) => DateTime.parse(item),
          ),
        );
      default:
        throw Exception(
            "scientisst_db cannot cast this type of object - Value: $value, Type: ${value.runtimeType.toString()} - into $type");
    }
  }

  Future<String> get _absolutePath async =>
      ScientISSTdb._joinPaths(await ScientISSTdb._dbDirPath, _filePath);

  Future<Directory> export({String dest}) async {
    final String path = ScientISSTdb._joinPaths(
        dest ?? (await getTemporaryDirectory()).path, '$id.db');

    final result = Directory(path);
    result.createSync(recursive: true);

    final File document = await _file;
    final File metadata = await _metadata._file;
    final Directory collections = await _collections;

    final String documentPath = ScientISSTdb._joinPaths(path, "document");
    final String metadataPath = ScientISSTdb._joinPaths(path, "metadata");
    final String collectionsPath = ScientISSTdb._joinPaths(path, "collections");

    document.copySync(documentPath);
    metadata.copySync(metadataPath);
    ScientISSTdb._copyDirectory(collections, collectionsPath);

    return result;
  }

  Future<void> import(File file) async {
    // TODO
  }
}
