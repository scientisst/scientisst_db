part of 'scientisst_db.dart';

class MetadataSnapshot {
  _MetadataReference _reference;
  Map<String, dynamic> _data;

  MetadataSnapshot(_MetadataReference reference, Map<String, dynamic> data) {
    _reference = reference;
    _data = data;
  }

  Map<String, String> get fieldsType =>
      Map<String, String>.from(_data["fieldsType"] ?? {});
  DateTime get createdAt => _data["createdAt"];
  DateTime get lastModified => _data["lastModified"];
}
