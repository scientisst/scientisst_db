part of "scientisst_db.dart";

class CollectionReference {
  Directory reference;
  final DocumentReference parent;

  CollectionReference._(String path, {this.parent}) {
    assert(!path.contains("/") && !path.contains("."));
    reference = Directory(path);
  }

  CollectionReference._fromDirectory(Directory directory, {this.parent}) {
    reference = directory;
  }

  DocumentReference document(String path) {
    assert(!path.contains("/") && !path.contains("."));
    return DocumentReference._(ScientISSTdb._joinPaths(reference.path, path),
        parent: this);
  }

  Future<List<DocumentSnapshot>> getDocuments() async {
    try {
      return await Future.wait(
        reference.listSync().where((file) => file.path.endsWith(".json")).map(
            (file) async =>
                await DocumentReference._fromFile(file, parent: this).get()),
      );
    } on FileSystemException catch (e) {
      if (e.osError.errorCode != 2)
        throw e; // if error is not "No such file or directory"
      return null;
    }
  }

  Future<DocumentReference> add(Map<String, dynamic> data) async {
    DocumentReference document = DocumentReference._(
        ScientISSTdb._joinPaths(reference.path, ObjectId().id),
        parent: this);
    await document.setData(data);
    return document;
  }

  Future<void> _checkEmpty() async {
    try {
      await reference.delete();
    } on FileSystemException catch (e) {
      if (e.osError.errorCode != 39)
        throw e; // if error is not "Directory not empty"
    }
  }

  String get path {
    return reference.path;
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
      reference,
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
        reference,
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
