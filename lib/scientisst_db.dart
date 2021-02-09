import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

part 'document_reference.dart';
part 'collection_reference.dart';
part 'object_id.dart';
part 'document_snapshot.dart';
part 'query.dart';

const APP_NAME = "scientisst_journal";
const DB_PATH = "scientisst_db";
const MAXIMUM_COUNTER = 16777216; // 3 bytes

class ScientISSTdb {
  static Future<Directory> _rootDir = getApplicationDocumentsDirectory();
  static ScientISSTdb _cachedInstance;
  static String _cachedPath;
  int _counterVal = Random().nextInt(MAXIMUM_COUNTER) - 1;

  int get _counter {
    final int counter = _counterVal++;
    if (_counterVal >= MAXIMUM_COUNTER) _counterVal = 0;
    return counter;
  }

  static ScientISSTdb get instance {
    if (_cachedInstance != null) {
      return _cachedInstance;
    }

    _cachedInstance = ScientISSTdb();

    return _cachedInstance;
  }

  static Future<String> get _dbDir async {
    if (_cachedPath != null) {
      return _cachedPath;
    }

    _cachedPath = _joinPaths((await _rootDir).path, DB_PATH);
    return _cachedPath;
  }

  CollectionReference collection(String path) {
    return CollectionReference._(parent: null, path: path);
  }

  static Future<Directory> _getDirectory([String path]) async =>
      Directory(_joinPaths(await _dbDir, path ?? ""));

  static Future<File> _getFile(String path) async =>
      File(_joinPaths(await _dbDir, path));

  static String _joinPaths(String path1, String path2) {
    String path1strip = path1;
    if (path1strip.startsWith("/")) path1strip = path1strip.substring(1);
    if (path1strip.endsWith("/"))
      path1strip = path1strip.substring(0, path1strip.length);

    String path2strip = path2;
    if (path2strip.startsWith("/")) path2strip = path2strip.substring(1);
    if (path2strip.endsWith("/"))
      path2strip = path2strip.substring(0, path2strip.length);

    return "$path1strip/$path2strip";
  }

  Future<List<String>> listCollections() async {
    final Directory rootDir = (await _getDirectory());
    try {
      return List<String>.from(
        rootDir.listSync().where((file) => file is Directory).map(
              (file) => file.path.split("/").last,
            ),
      );
    } on FileSystemException catch (e) {
      if (e.osError.errorCode != 2)
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
}
