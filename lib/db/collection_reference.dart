part of "../scientisst_db.dart";

class CollectionReference {
  String _directoryPath;
  String _documentsPath;
  String _metadataPath;
  String _collectionsPath;
  final DocumentReference parent;

  CollectionReference._({@required this.parent, @required path}) {
    assert(path != null &&
        path.isNotEmpty &&
        !path.contains(".") &&
        !path.contains("/"));
    if (parent != null) {
      _directoryPath = ScientISSTdb._joinPaths(parent._collectionsPath, path);
    } else {
      _directoryPath = ScientISSTdb._joinPaths(DB_PATH, path);
    }

    _documentsPath = ScientISSTdb._joinPaths(_directoryPath, "documents");
    _metadataPath = ScientISSTdb._joinPaths(_directoryPath, "metadata");
    _collectionsPath = ScientISSTdb._joinPaths(_directoryPath, "collections");
  }

  Future<Directory> get _directory async =>
      await ScientISSTdb._getDirectory(_directoryPath);
  Future<Directory> get _documents async =>
      await ScientISSTdb._getDirectory(_documentsPath);

  DocumentReference document(String path) {
    assert(!path.contains("/") && !path.contains("."));
    return DocumentReference._(parent: this, path: path);
  }

  Future<List<String>> listDocuments() async {
    final Directory documents = await _documents;
    try {
      return List<String>.from(
        documents.listSync().where((file) => file is File).map(
              (file) => file.path.split("/").last,
            ),
      );
    } on FileSystemException catch (e) {
      if (e.osError.errorCode != 2)
        throw e; // if error is not "No such file or directory"
      return [];
    }
  }

  Future<List<DocumentSnapshot>> getDocuments() async {
    final List<String> documents = await listDocuments();
    return await Future.wait(
      documents.map(
          (String documentID) async => await this.document(documentID).get()),
    );
  }

  Stream<List<DocumentSnapshot>> watchDocuments() async* {
    List<DocumentSnapshot> docs = await getDocuments();
    yield docs;
    await for (WatchEvent event
        in DirectoryWatcher(await _absoluteDocumentsPath).events) {
      docs = await getDocuments();
      yield (docs);
    }
  }

  Future<DocumentReference> add(Map<String, dynamic> data) async {
    final DocumentReference document =
        DocumentReference._(parent: this, path: ObjectId().id);
    await document.setData(data);
    return document;
  }

  Future<void> delete() async {
    (await _directory).deleteSync(recursive: true);
  }

  Future<void> _deleteEmpty() async {
    try {
      await (await _documents)
          .delete(); // if this deletes, it is safe to delete directory recursively
      (await _directory).deleteSync(recursive: true);
    } on FileSystemException catch (e) {
      if (e.osError.errorCode != 39)
        throw e; // if error is not "Directory not empty"
    }
  }

  Future<String> get _absolutePath async =>
      ScientISSTdb._joinPaths(await ScientISSTdb._dbDirPath, _directoryPath);

  Future<String> get _absoluteDocumentsPath async =>
      ScientISSTdb._joinPaths(await ScientISSTdb._dbDirPath, _documentsPath);

  Query where(String field,
      {dynamic isEqualTo,
      dynamic isLessThan,
      dynamic isLessThanOrEqualTo,
      dynamic isGreaterThan,
      dynamic isGreaterThanOrEqualTo,
      bool isNull}) {
    final List<dynamic> values = [
      isEqualTo,
      isLessThan,
      isLessThanOrEqualTo,
      isGreaterThan,
      isGreaterThanOrEqualTo,
      isNull,
    ];
    return Query._(
      this,
      [
        Query._getWhere(field: field, values: values),
      ],
    );
  }

  Query orderBy(String field, {bool descending = false}) => Query._(
        this,
        [
          Query._getOrderBy(
            field: field,
            descending: descending,
          ),
        ],
      );

  Future<File> export() async {
    // TODO
    ZipFileEncoder encoder = ZipFileEncoder();
    final String collectionName = _directoryPath.split("/").last;
    final String filepath = ScientISSTdb._joinPaths(
        (await getTemporaryDirectory()).path, '$collectionName.zip');
    encoder.zipDirectory(await _directory, filename: filepath);
  }

  Future<void> import(File file) async {
    if (file.path.endsWith(".db.zip")) {
      // Read the Zip file from disk.
      final bytes = file.readAsBytesSync();
      final String id = file.path.split("/").last.split(".").first;

      await importFromBytes(bytes, id);
    } else {
      throw Exception("This is not a db file");
    }
  }

  Future<void> importFromBytes(List<int> bytes, String id) async {
    // Decode the Zip file
    final Archive archive = ZipDecoder().decodeBytes(bytes);

    final DocumentReference doc = document(id);
    await doc._init();
    final String collectionsPath = (await doc._collections).path;

    // Extract the contents of the Zip archive to disk.
    for (final ArchiveFile file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final List<int> data = file.content as List<int>;
        if (filename == "document") {
          (await doc._file).writeAsBytesSync(data);
        } else if (filename == "metadata") {
          (await doc._metadata._file).writeAsBytesSync(data);
        } else {
          File(ScientISSTdb._joinPaths(collectionsPath, file.name))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
      }
    }
  }
}
