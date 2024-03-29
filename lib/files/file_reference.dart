part of '../scientisst_db.dart';

class FileReference {
  late String _path;
  late DirectoryReference parent;

  FileReference._({required String path, required this.parent}) {
    assert(path.isNotEmpty);
    _path = ScientISSTdb._joinPaths(parent._path, path);
  }

  String get path => _path.substring(FILES_PATH.length + 1);
  String get name => _path.split("/").last;
  Future<String> get absolutePath async =>
      ScientISSTdb._joinPaths(await ScientISSTdb._dbDirPath, _path);

  Future<File> getFile() async => await ScientISSTdb._getFile(_path);

  Future<Uint8List> getBytes() async =>
      (await ScientISSTdb._getFile(_path)).readAsBytesSync();

  Future<void> putFile(File file) async {
    putBytes(file.readAsBytesSync());
  }

  Future<void> putBytes(Uint8List bytes) async {
    File _file = await ScientISSTdb._getFile(_path);
    _file = await _file.create(recursive: true);
    try {
      _file.writeAsBytesSync(bytes);
    } on FileSystemException catch (e) {
      print(e);
    }
  }

  Future<void> delete() async {
    final File _file = await ScientISSTdb._getFile(_path);
    _file.deleteSync();
    await parent._deleteEmpty();
  }
}
