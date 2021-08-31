part of '../scientisst_db.dart';

class DirectoryReference {
  String _path;
  DirectoryReference parent;

  DirectoryReference._({@required String path, this.parent}) {
    assert(path != null && path.isNotEmpty && !path.contains("."));
    if (parent != null) {
      _path = ScientISSTdb._joinPaths(parent._path, path);
    } else {
      _path = path;
    }
  }

  String get path => _path.substring(FILES_PATH.length + 1);

  Future<Directory> get _directory async =>
      await ScientISSTdb._getDirectory(_path);

  Future<String> get absolutePath async =>
      ScientISSTdb._joinPaths(await ScientISSTdb._dbDirPath, _path);

  FileReference file(String path) => FileReference._(
        path: path,
        parent: this,
      );

  DirectoryReference directory(String path) => DirectoryReference._(
        path: path,
        parent: this,
      );

  Future<List<String>> listFiles() async {
    final Directory dir = await _directory;
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
    final Directory dir = await _directory;
    dir.createSync(recursive: true);
    await file
        .copy(ScientISSTdb._joinPaths(await ScientISSTdb._dbDirPath, _path));
    await file.delete();
  }

  Future<FileReference> putBytes(Uint8List bytes, String filename) async {
    assert(!filename.contains("/"));
    final Directory dir = await _directory;
    dir.createSync(recursive: true);
    final File file =
        await ScientISSTdb._getFile(ScientISSTdb._joinPaths(_path, filename));
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

  Future<void> delete() async {
    (await _directory).deleteSync(recursive: true);
  }

  Future<void> _deleteEmpty() async {
    try {
      (await _directory).deleteSync();
    } on FileSystemException catch (e) {
      if (e.osError.errorCode != 39)
        throw e; // if error is not "Directory not empty"
    }
  }
}
