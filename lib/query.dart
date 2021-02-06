part of 'scientisst_db.dart';

enum Operator {
  isEqualTo,
  isLessThan,
  isLessThanOrEqualTo,
  isGreaterThan,
  isGreaterThanOrEqualTo,
  isNull
}

enum ConditionType {
  where,
  orderBy,
}

class Query {
  final Directory _directory;
  final CollectionReference reference;
  final List<Map<String, dynamic>> _query;

  Query._(this._directory, this.reference, this._query);

  Future<List<DocumentSnapshot>> getDocuments() async {
    List<DocumentSnapshot> docs;
    try {
      docs = await Future.wait(
        _directory.listSync().where((file) => file.path.endsWith(".json")).map(
              (file) async =>
                  await DocumentReference._fromFile(file, parent: reference)
                      .get(),
            ),
      );
    } on FileSystemException catch (e) {
      if (e.osError.errorCode != 2)
        throw e; // if error is not "No such file or directory"
      return null;
    }

    for (Map<String, dynamic> condition in _query) {
      switch (condition["type"]) {
        case ConditionType.where:
          final dynamic field = condition["field"];
          final Operator operator = condition["operator"];
          final dynamic value = condition["value"];
          docs = docs.where(
              (DocumentSnapshot doc) => _checkOperator(field, operator, value));
          break;
        case ConditionType.orderBy:
          int a, b;
          if (condition["ascending"]) {
            a = 1;
            b = -1;
          } else {
            a = -1;
            b = 1;
          }
          final String field = condition["field"];
          docs.sort((DocumentSnapshot doc1, DocumentSnapshot doc2) {
            if (doc1.data[field] > doc2.data[field]) {
              return a;
            } else {
              if (doc1.data[field] != doc2.data[field])
                return b;
              else
                return 0;
            }
          });
          break;
        default:
          break;
      }
      return List<DocumentSnapshot>.from(docs);
    }
  }

  bool _checkOperator(dynamic field, Operator operator, dynamic value) {
    switch (operator) {
      case Operator.isNull:
        return field == null;
      case Operator.isGreaterThan:
        return field > value;
      case Operator.isGreaterThanOrEqualTo:
        return field >= value;
      case Operator.isLessThan:
        return field < value;
      case Operator.isLessThanOrEqualTo:
        return field <= value;
      default:
        return false;
    }
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
      reference,
      _query
        ..addAll(
          [
            {
              "type": ConditionType.where,
              "field": field,
              "operator": operator,
              "value": value
            },
          ],
        ),
    );
  }

  Query orderBy(String field, {bool ascending = false}) => Query._(
        _directory,
        reference,
        _query
          ..addAll(
            [
              {
                "type": ConditionType.orderBy,
                "field": field,
                "ascending": ascending,
              },
            ],
          ),
      );
}
