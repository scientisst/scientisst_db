part of "scientisst_db.dart";

class CollectionReference {
  Directory _directory;
  final DocumentReference parent;

  CollectionReference._(String path, {this.parent}) {
    _directory = Directory(path);
  }

  CollectionReference._fromDirectory(Directory directory, {this.parent}) {
    _directory = directory;
  }

  DocumentReference document(String path) {
    assert(!path.contains("/") && !path.contains("."));
    return DocumentReference._(ScientISSTdb._joinPaths(_directory.path, path),
        parent: this);
  }

  Future<List<DocumentSnapshot>> getDocuments() async {
    try {
      return await Future.wait(
        _directory
            .listSync()
            .where((file) => file is File && file.path.endsWith(".json"))
            .map((file) async =>
                await DocumentReference._fromFile(file, parent: this).get()),
      );
    } on FileSystemException catch (e) {
      if (e.osError.errorCode != 2)
        throw e; // if error is not "No such file or directory"
      return null;
    }
  }

  Future<DocumentReference> add(Map<String, dynamic> data) async {
    final DocumentReference document = DocumentReference._(
        ScientISSTdb._joinPaths(_directory.path, ObjectId().id),
        parent: this);
    await document.setData(data);
    return document;
  }

  Future<void> _checkEmpty() async {
    try {
      await _directory.delete();
    } on FileSystemException catch (e) {
      if (e.osError.errorCode != 39)
        throw e; // if error is not "Directory not empty"
    }
  }

  String get path {
    return _directory.path;
  }

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
    assert(values.where((dynamic operator) => operator != null).length == 1);

    final int index = values.indexOf((dynamic operator) => operator != null);
    Operator operator = [
      Operator.isEqualTo,
      Operator.isLessThan,
      Operator.isLessThanOrEqualTo,
      Operator.isGreaterThan,
      Operator.isGreaterThanOrEqualTo,
      Operator.isNull,
    ][index];
    dynamic value = values[index];

    return Query._(
      _directory,
      this,
      [
        {
          "type": ConditionType.where,
          "field": field,
          "operator": operator,
          "value": value
        }
      ],
    );
  }

  Query orderBy(String field, {bool ascending = false}) => Query._(
        _directory,
        this,
        [
          {
            "type": ConditionType.orderBy,
            "field": field,
            "ascending": ascending,
          }
        ],
      );
}
