part of '../scientisst_db.dart';

class MetadataSnapshot {
  late _MetadataReference _reference;
  late Map<String, dynamic>? _data;

  MetadataSnapshot(_MetadataReference reference, Map<String, dynamic>? data) {
    _reference = reference;
    _data = data;
  }

  DateTime get createdAt => _data?["createdAt"];

  DateTime get lastModified => _data?["lastModified"];
}
