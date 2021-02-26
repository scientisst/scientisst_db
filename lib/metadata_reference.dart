part of "scientisst_db.dart";

class _MetadataReference {
  DocumentReference parent;
  String _path;

  _MetadataReference({@required this.parent, @required String path}) {
    _path = path;
  }

  Future<void> init() async {
    final File file = await _file;
    if (!file.existsSync()) {
      file.createSync(recursive: true);
      await _setCreatedAt();
    }
  }

  Future<void> delete() async => (await _file).deleteSync();

  Future<File> get _file async => await ScientISSTdb._getFile(_path);

  Future<void> _updateData(Map<String, dynamic> data) async {
    Map<String, dynamic> _data = await _read();
    _data.addAll(data);
    await _write(_data);
  }

  Future<Map<String, dynamic>> _read() async {
    try {
      return jsonDecode((await _file).readAsStringSync());
    } on FormatException catch (e) {
      return {};
    } on FileSystemException catch (e) {
      throw e;
    }
  }

  Future<void> _write(Map<String, dynamic> data) async {
    await (await _file).writeAsString(
      jsonEncode(data, toEncodable: _myEncode),
    );
  }

  dynamic _myEncode(dynamic item) {
    if (item is DateTime) {
      return item.toIso8601String();
    }
    return item;
  }

  Future<void> _setCreatedAt() async =>
      await _updateData({"createdAt": DateTime.now()});

  //Future<void> setLastModified() async =>
  //await _updateData({"lastModified": DateTime.now()});

  Future<void> setFieldTypes(Map<String, dynamic> data) async {
    final Map<String, String> types = data.map(
      (String key, dynamic value) =>
          MapEntry(key, value.runtimeType.toString()),
    );
    await _updateData({
      "fieldsType": types,
      "lastModified": DateTime.now(),
    });
  }

  Future<MetadataSnapshot> get() async => MetadataSnapshot(this, await _read());
}
