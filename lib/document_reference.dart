part of "scientisst_db.dart";

class DocumentReference {
  ObjectId objectId;
  final CollectionReference parent;
  File _file;
  Directory _collections;

  DocumentReference._(String path, {this.parent}) {
    assert(!path.contains("/") && !path.contains("."));
    final File file = File("$path.json");
    _file = file;
    objectId = ObjectId(path.split("/").last);
    _collections = Directory(path);
  }

  DocumentReference._fromFile(File file, {this.parent}) {
    _file = file;
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
      if (data == null || data.isEmpty) {
        await delete();
      } else {
        await _write(data);
      }
    }
  }

  Future<void> _write(Map<String, dynamic> data) async {
    await _file.writeAsString(jsonEncode(data));
  }

  Future<void> updateData(Map<String, dynamic> data) async {
    Map<String, dynamic> _data = await _read();
    _data.addAll(data);
    await _write(_data);
  }

  Future<void> _init() async {
    await _file.create(recursive: true);
  }

  Future<void> delete() async {
    await _file.delete();
    await _collections.delete(recursive: true);
    await parent._checkEmpty();
  }

  String get id {
    return objectId.id;
  }

  Future<Map<String, dynamic>> _read() async {
    return jsonDecode(await _file.readAsString());
  }

  Future<DocumentSnapshot> get() async {
    return DocumentSnapshot(this, await _read());
  }

  String get path {
    return path;
  }
}
