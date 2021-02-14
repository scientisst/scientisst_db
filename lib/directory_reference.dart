part of 'scientisst_db.dart';

class DirectoryReference {
  String _path;
  DirectoryReference parent;

  DirectoryReference._({@required String path, this.parent}) {
    assert(!path.contains(".") && !path.contains("/"));
    this._path = path;
  }

  String get path => _path;

  Future<Directory> get _dir async => await ScientISSTdb._getDirectory(_path);

  Future<String> get absolutePath async =>
      ScientISSTdb._joinPaths(await ScientISSTdb._dbDirPath, _path);

  FileReference file(String path) => FileReference._(
        path: ScientISSTdb._joinPaths(_path, path),
        parent: this,
      );

  DirectoryReference directory(String path) => DirectoryReference._(
        path: ScientISSTdb._joinPaths(_path, path),
        parent: this,
      );

  Future<List<String>> listFiles() async {
    final Directory dir = await _dir;
    try {
      return List<String>.from(
        dir.listSync().where((file) => file is File).map(
              (file) => file.path.split("/").last,
            ),
      );
    } on FileSystemException catch (e) {
      if (e.osError.errorCode != 2)
        throw e; // if error is not "No such file or directory"
      return [];
    }
  }

  Future<FileReference> putFile(File file) async {
    final Directory dir = await _dir;
    dir.create(recursive: true);
    await file
        .copy(ScientISSTdb._joinPaths(await ScientISSTdb._dbDirPath, _path));
    await file.delete();
  }

  Future<FileReference> putBytes(Uint8List bytes, String filename) async {
    assert(!path.contains("/"));
    final Directory dir = await _dir;
    dir.create(recursive: true);
    final File file = File(ScientISSTdb._joinPaths(_path, filename));
    file.writeAsBytesSync(bytes);
    return FileReference._(path: filename, parent: this);
  }

  Future<List<FileReference>> getFiles() async {
    final List<String> collections = await listFiles();
    return List<FileReference>.from(
      collections.map(
        (String path) => FileReference._(path: path),
      ),
    );
  }

  Future<void> _deleteEmpty() async {
    final Directory dir = await ScientISSTdb._getDirectory(_path);
    try {
      await dir.delete();
    } on FileSystemException catch (e) {
      if (e.osError.errorCode != 39)
        throw e; // if error is not "Directory not empty"
    }
  }
}
