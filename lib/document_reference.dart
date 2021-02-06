part of "scientisst_db.dart";

class DocumentReference {
  ObjectId objectId;
  final CollectionReference parent;
  File reference;
  Directory _collections;

  DocumentReference._(String path, {this.parent}) {
    assert(!path.contains("/") && !path.contains("."));
    final File file = File("$path.json");
    reference = file;
    objectId = ObjectId(path.split("/").last);
    _collections = Directory(path);
  }

  DocumentReference._fromFile(File file, {this.parent}) {
    reference = file;
  }

  CollectionReference collection(String path) {
    assert(!path.contains("/") && !path.contains("."));
    return CollectionReference._(
      ScientISSTdb._joinPaths(
        _collections.path,
        path,
      ),
      parent: this,
    );
  }

  Future<void> setData(Map<String, dynamic> data, {bool merge: false}) async {
    await _init();
    if (merge) {
      await updateData(data);
    } else {
      await reference.writeAsString(jsonEncode(data));
    }
  }

  Future<void> updateData(Map<String, dynamic> data) async {
    Map<String, dynamic> _data = await _read();
    _data.addAll(data);
    await reference.writeAsString(jsonEncode(_data));
  }

  Future<void> _init() async {
    await reference.create(recursive: true);
  }

  Future<void> delete() async {
    await reference.delete();
    await _collections.delete(recursive: true);
    await parent._checkEmpty();
  }

  String get id {
    return objectId.id;
  }

  Future<Map<String, dynamic>> _read() async {
    return jsonDecode(await reference.readAsString());
  }

  Future<DocumentSnapshot> get() async {
    return DocumentSnapshot(this, await _read());
  }

  String get path {
    return path;
  }
}
