part of '../scientisst_db.dart';

class DocumentSnapshot {
  final DocumentReference reference;
  final Map<String, dynamic> data;
  final MetadataSnapshot metadata;

  DocumentSnapshot(this.reference, this.data, this.metadata);

  String get id => reference.id;

  ObjectId get objectId => ObjectId(id);
}
