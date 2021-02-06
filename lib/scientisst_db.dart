import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

part 'document_reference.dart';
part 'collection_reference.dart';
part 'object_id.dart';
part 'document_snapshot.dart';
part 'query.dart';

const APP_NAME = "scientisst_journal";

class ScientISSTdb {
  Directory _rootDir;
  static final Map<String, ScientISSTdb> _cachedInstances = {};
  int _counterVal = Random().nextInt(8) - 1;

  int get _counter {
    final int counter = _counterVal++;
    if (_counterVal >= 8) _counterVal = 0;
    return counter;
  }

  ScientISSTdb() {
    if (Platform.isAndroid) {
      _rootDir = Directory("/data/user/0/com.scientisst.journal/scientisst_db");
    } else if (Platform.isIOS) {
      // TODO
    } else {
      throw Exception("Platform not supported");
    }
  }

  static ScientISSTdb get instance {
    if (_cachedInstances.containsKey(APP_NAME)) {
      return _cachedInstances[APP_NAME];
    }

    ScientISSTdb newInstance = ScientISSTdb();
    _cachedInstances[APP_NAME] = newInstance;

    return newInstance;
  }

  DocumentReference document(String path) {
    return DocumentReference._(_joinPaths(_rootDir.path, path));
  }

  CollectionReference collection(String path) {
    return CollectionReference._(_joinPaths(_rootDir.path, path));
  }

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
}
