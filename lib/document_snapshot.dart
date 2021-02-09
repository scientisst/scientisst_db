part of 'scientisst_db.dart';

class DocumentSnapshot {
  DocumentReference reference;
  Map<String, dynamic> data;

  DocumentSnapshot(this.reference, this.data);

  String get id => reference.id;

  ObjectId get objectId => ObjectId(id);
}
