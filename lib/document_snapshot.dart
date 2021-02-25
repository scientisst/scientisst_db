part of 'scientisst_db.dart';

class DocumentSnapshot {
  DocumentReference reference;
  Map<String, dynamic> data;

  DocumentSnapshot(this.reference, this.data);

  String get id => reference.id;

  ObjectId get objectId => ObjectId(id);

  void _updateFieldsType(Map<String, String> fieldsType) {
    data = data.map(
      (String key, dynamic value) {
        if (value.runtimeType.toString() == fieldsType["key"]) {
          return MapEntry(key, value);
        } else {
          return MapEntry(
            key,
            _convertToType(
              value,
              fieldsType["key"],
            ),
          );
        }
      },
    );
  }

  dynamic _convertToType(dynamic value, String type) {
    switch (type) {
      case "DateTime":
        return DateTime.parse(value);
      default:
        throw Exception("scientisst_db cannot encode this type of file");
    }
  }
}
