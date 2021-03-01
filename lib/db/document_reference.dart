part of "../scientisst_db.dart";

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

  Future<void> setData(Map<String, dynamic> data, {bool merge: false}) async {
    if (!(await _file).existsSync()) await _init();
    if (merge) {
      await updateData(data);
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
    }
    return item;
  }

  Future<void> updateData(Map<String, dynamic> data) async {
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
      final Map<String, dynamic> data =
          jsonDecode((await _file).readAsStringSync());
      return _updateFieldsType(data, (await _metadata.get()).fieldsType);
    } on FormatException catch (e) {
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
    await for (WatchEvent event in FileWatcher(await _absolutePath).events) {
      doc = await get();
      yield doc;
    }
  }

  static dynamic _convertToType(dynamic value, String type) {
    switch (type) {
      case "DateTime":
        return DateTime.parse(value);
      default:
        throw Exception(
            "scientisst_db cannot encode this type of object: $type");
    }
  }

  static Map<String, dynamic> _updateFieldsType(
      Map<String, dynamic> data, Map<String, String> fieldsType) {
    if (fieldsType.isNotEmpty) {
      return data.map(
        (String key, dynamic value) {
          if (value.runtimeType.toString() == fieldsType[key]) {
            return MapEntry(key, value);
          } else {
            return MapEntry(
              key,
              _convertToType(
                value,
                fieldsType[key],
              ),
            );
          }
        },
      );
    }
  }

  Future<String> get _absolutePath async =>
      ScientISSTdb._joinPaths(await ScientISSTdb._dbDirPath, _filePath);

  Future<File> export() async {
    ZipFileEncoder encoder = ZipFileEncoder();

    final String filepath = ScientISSTdb._joinPaths(
        (await getTemporaryDirectory()).path, '$id.db.zip');
    encoder.create(filepath);
    try {
      encoder.addFile(await _file, "document");
    } on FileSystemException catch (e) {
      if (e.osError.errorCode != 2)
        throw e; // if error is not "No such file or directory"
      return null;
    }

    encoder.addFile(await _metadata._file, "metadata");
    encoder.addDirectory(await _collections, includeDirName: false);
    encoder.close();

    return File(filepath);
  }

  Future<void> import(File file) async {
    // TODO
    // Read the Zip file from disk.
    final bytes = file.readAsBytesSync();

    // Decode the Zip file
    final archive = ZipDecoder().decodeBytes(bytes);

    // Extract the contents of the Zip archive to disk.
    for (final file in archive) {
      final filename = file.name;
      print(filename);
      /*if (file.isFile) {
        final data = file.content as List<int>;
      } else {
        Directory('out/' + filename)..create(recursive: true);
      }*/
    }
  }
}
