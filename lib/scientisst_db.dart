import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:watcher/watcher.dart';

part 'db/document_reference.dart';
part 'db/collection_reference.dart';
part 'db/object_id.dart';
part 'db/document_snapshot.dart';
part 'db/query.dart';
part 'db/metadata_reference.dart';
part 'db/metadata_snapshot.dart';
part 'files/file_reference.dart';
part 'files/directory_reference.dart';

const PACKAGE_PATH = "scientisst_db";
const DB_PATH = "db";
const FILES_PATH = "files";

const MAXIMUM_COUNTER = 16777216; // 3 bytes

class ScientISSTdb {
  static Future<Directory> _rootDir = Platform.isIOS
      ? getLibraryDirectory()
      : getApplicationDocumentsDirectory();
  //: getExternalStorageDirectory();

  static ScientISSTdb? _cachedInstance;
  static String? _cachedPath;
  int _counterVal = Random().nextInt(MAXIMUM_COUNTER) - 1;

  int get _counter {
    final int counter = _counterVal++;
    if (_counterVal >= MAXIMUM_COUNTER) _counterVal = 0;
    return counter;
  }

  static ScientISSTdb get instance {
    if (_cachedInstance != null) {
      return _cachedInstance!;
    }

    _cachedInstance = ScientISSTdb();

    return _cachedInstance!;
  }

  static Future<String?> get _dbDirPath async {
    if (_cachedPath != null) {
      return _cachedPath;
    }

    _cachedPath = _joinPaths((await _rootDir).path, PACKAGE_PATH);
    return _cachedPath;
  }

  DirectoryReference get files => DirectoryReference._(path: FILES_PATH);

  static Future<Directory> _getDirectory([String? path]) async =>
      Directory(_joinPaths(await _dbDirPath, path));

  static Future<File> _getFile(String? path) async =>
      File(_joinPaths(await _dbDirPath, path));

  static String _joinPaths(dynamic paths, [String? path2]) {
    assert(paths != null);
    if (paths is String && path2 is String) {
      paths = _trimPath(paths);
      path2 = _trimPath(path2);
      return "$paths/$path2";
    } else if (paths is List<String>) {
      paths = List<String>.from(
        paths.map(
          (String path) => _trimPath(path),
        ),
      );
      return paths.join("/");
    } else {
      throw Exception("Cannot join invalid paths: $paths, ${path2 ?? ""}");
    }
  }

  static String _trimPath(String path) {
    if (path.startsWith("/")) {
      if (path.endsWith("/"))
        return path.substring(1, path.length - 1);
      else
        return path.substring(1);
    } else {
      if (path.endsWith("/"))
        return path.substring(0, path.length - 1);
      else
        return path;
    }
  }

  CollectionReference collection(String path) {
    return CollectionReference._(parent: null, path: path);
  }

  Future<List<String>> listCollections() async {
    final Directory rootDir = await _getDirectory(DB_PATH);
    try {
      return List<String>.from(
        rootDir.listSync().where((file) => file is Directory).map(
              (file) => file.path.split("/").last,
            ),
      );
    } on FileSystemException catch (e) {
      if (e.osError!.errorCode != 2)
        throw e; // if error is not "No such file or directory"
      return [];
    }
  }

  Future<List<CollectionReference>> getCollections() async {
    final List<String> collections = await listCollections();
    return List<CollectionReference>.from(
      collections.map(
        (String path) => CollectionReference._(parent: null, path: path),
      ),
    );
  }

  static Future<bool> clearDatabase({bool confirm = false}) async {
    if (confirm) {
      try {
        (await _getDirectory(DB_PATH)).deleteSync(recursive: true);
      } on FileSystemException catch (e) {
        if (e.osError!.errorCode != 2)
          throw e; // if error is not "No such file or directory"
      }
      return true;
    } else {
      return false;
    }
  }

  static dynamic _myEncode(dynamic item) {
    if (item is DateTime) {
      return item.toIso8601String();
    }
    return item;
  }
}
