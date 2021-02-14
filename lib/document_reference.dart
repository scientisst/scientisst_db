part of "scientisst_db.dart";

class DocumentReference {
  String objectId;
  CollectionReference parent;
  String _filePath;
  String _metadataPath;
  String _collectionsPath;

  DocumentReference._({@required this.parent, @required String path}) {
    assert(!path.contains(".") && !path.contains("/"));

    objectId = path;

    _filePath = ScientISSTdb._joinPaths(parent._documentsPath, path);
    _metadataPath = ScientISSTdb._joinPaths(parent._metadataPath, path);
    _collectionsPath = ScientISSTdb._joinPaths(parent._collectionsPath, path);
  }

  Future<File> get _file async => await ScientISSTdb._getFile(_filePath);
  Future<File> get _metadata async =>
      await ScientISSTdb._getFile(_metadataPath);
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
    await _init();
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
    (await _file).createSync(recursive: true);
    (await _metadata).createSync(recursive: true);
    (await _collections).createSync(recursive: true);
  }

  Future<void> delete() async {
    (await _file).deleteSync();
    (await _metadata).deleteSync();
    (await _collections).deleteSync(recursive: true);
    await parent?._deleteEmpty();
  }

  String get id {
    return objectId;
  }

  Future<Map<String, dynamic>> _read() async {
    try {
      return jsonDecode((await _file).readAsStringSync());
    } on FormatException catch (e) {
      print(e);
      return null;
    }
  }

  Future<DocumentSnapshot> get() async {
    return DocumentSnapshot(this, await _read());
  }

  Stream<DocumentSnapshot> watch() async* {
    DocumentSnapshot doc = await get();
    yield doc;
    await for (WatchEvent event in FileWatcher(await _absolutePath).events) {
      debugPrint(event.toString());
      doc = await get();
      yield doc;
    }
  }

  Future<String> get _absolutePath async =>
      ScientISSTdb._joinPaths(await ScientISSTdb._dbDirPath, _filePath);
}
