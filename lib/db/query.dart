part of '../scientisst_db.dart';

enum Operator {
  isEqualTo,
  isLessThan,
  isLessThanOrEqualTo,
  isGreaterThan,
  isGreaterThanOrEqualTo,
  isNull
}

const OPERATORS = [
  Operator.isEqualTo,
  Operator.isLessThan,
  Operator.isLessThanOrEqualTo,
  Operator.isGreaterThan,
  Operator.isGreaterThanOrEqualTo,
  Operator.isNull,
];

enum ConditionType {
  where,
  orderBy,
}

class Query {
  final CollectionReference reference;
  final List<Condition> _query;

  Query._(this.reference, this._query);

  static Where _getWhere(
      {required String field, required List<dynamic> values}) {
    assert(values.where((dynamic operator) => operator != null).length == 1);
    final index = values.indexWhere(
      (dynamic operator) => operator != null,
    );
    final operator = OPERATORS[index];
    final value = values[index];

    return Where(field: field, operator: operator, value: value);
  }

  static OrderBy _getOrderBy({required String field, bool? descending}) =>
      OrderBy(field: field, descending: descending!);

  Future<List<String>> listDocuments() async {
    final Directory documents = await reference._documents;
    try {
      return List<String>.from(
        documents.listSync().where((file) => file is File).map(
              (file) => file.path.split("/").last,
            ),
      );
    } on FileSystemException catch (e) {
      if (e.osError!.errorCode != 2)
        throw e; // if error is not "No such file or directory"
      return [];
    }
  }

  Future<List<DocumentSnapshot>> getDocuments() async {
    final documents = await listDocuments();
    List<DocumentSnapshot> snaps = await Future.wait(
      documents.map((String documentID) async =>
          await DocumentReference._(parent: reference, path: documentID).get()),
    );

    if (snaps.isNotEmpty) {
      for (Condition condition in _query) {
        if (condition is Where) {
          final Where whereCondition = condition;
          snaps = List<DocumentSnapshot>.from(
            snaps.where(
              (DocumentSnapshot doc) {
                return _checkOperator(doc.data[whereCondition.field],
                    whereCondition.operator, whereCondition.value);
              },
            ),
          );
        } else if (condition is OrderBy) {
          final OrderBy orderByCondition = condition;
          snaps.sort(
            (DocumentSnapshot doc1, DocumentSnapshot doc2) => _compare(
              doc1.data[orderByCondition.field],
              doc2.data[orderByCondition.field],
              descending: orderByCondition.descending,
            ),
          );
        }
      }
    }
    return snaps;
  }

  Stream<List<DocumentSnapshot>> watchDocuments() async* {
    List<DocumentSnapshot> docs = await getDocuments();
    yield docs;
    await for (final _
        in DirectoryWatcher(await reference._absoluteDocumentsPath).events) {
      docs = await getDocuments();
      yield (docs);
    }
  }

  int _compare(dynamic value1, dynamic value2, {bool descending: false}) {
    final _descending = (descending ? 1 : -1);
    if (value1 is num && value2 is num) {
      if (value1 == value2) return 0;
      if (value1 > value2)
        return 1 * _descending;
      else
        return -1 * _descending;
    } else if (value1 is String && value2 is String) {
      return value1.compareTo(value2) * _descending;
    } else if (value1 is DateTime && value2 is DateTime) {
      if (value1.isAtSameMomentAs(value2)) return 0;
      if (value1.isBefore(value2)) return 1 * _descending;
      return -1 * _descending;
    } else {
      return 0;
    }
  }

  bool _checkOperator(dynamic field, Operator operator, dynamic value) {
    if (field is num && value is num) {
      return _checkOperatorNum(field, operator, value);
    } else if (field is String && value is String) {
      return _checkOperatorString(field, operator, value);
    } else if (operator == Operator.isNull) {
      return field == null;
    } else {
      return false;
    }
  }

  bool _checkOperatorString(String field, Operator operator, String value) {
    final comparison = field.compareTo(value);
    switch (operator) {
      case Operator.isGreaterThan:
        return comparison > 0;
      case Operator.isGreaterThanOrEqualTo:
        return comparison > 0 || comparison == 0;
      case Operator.isLessThan:
        return comparison < 0;
      case Operator.isLessThanOrEqualTo:
        return comparison < 0 || comparison == 0;
      case Operator.isEqualTo:
        return comparison == 0;
      default:
        return false;
    }
  }

  bool _checkOperatorNum(num field, Operator operator, num value) {
    switch (operator) {
      case Operator.isGreaterThan:
        return field > value;
      case Operator.isGreaterThanOrEqualTo:
        return field >= value;
      case Operator.isLessThan:
        return field < value;
      case Operator.isLessThanOrEqualTo:
        return field <= value;
      case Operator.isEqualTo:
        return field == value;
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
      bool? isNull}) {
    final List<dynamic> values = [
      isEqualTo,
      isLessThan,
      isLessThanOrEqualTo,
      isGreaterThan,
      isGreaterThanOrEqualTo,
      isNull,
    ];
    return Query._(
      reference,
      _query
        ..addAll(
          [_getWhere(field: field, values: values)],
        ),
    );
  }

  Query orderBy(String field, {bool descending = false}) => Query._(
        reference,
        _query
          ..addAll(
            [_getOrderBy(field: field, descending: descending)],
          ),
      );
}

class Condition {}

class OrderBy extends Condition {
  final String field;
  final bool descending;
  OrderBy({required this.field, this.descending = false});
}

class Where extends Condition {
  final String field;
  final Operator operator;
  final dynamic value;
  Where({required this.field, required this.operator, required this.value});
}
