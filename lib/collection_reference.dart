part of "scientisst_db.dart";

class CollectionReference {
  String _directoryPath;
  String _documentsPath;
  String _metadataPath;
  String _collectionsPath;
  final DocumentReference parent;

  CollectionReference._({@required this.parent, @required path}) {
    assert(!path.contains(".") && !path.contains("/"));
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
      debugPrint("${DateTime.now()} ${event}");
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

  Query orderBy(String field, {bool ascending = false}) => Query._(
        this,
        [
          Query._getOrderBy(
            field: field,
            ascending: ascending,
          ),
        ],
      );
}
