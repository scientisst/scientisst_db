part of '../scientisst_db.dart';

class DocumentSnapshot {
  DocumentReference reference;
  Map<String, dynamic> data;
  MetadataSnapshot metadata;

  DocumentSnapshot(this.reference, this.data, this.metadata);

  String get id => reference.id;

  ObjectId get objectId => ObjectId(id);
}
