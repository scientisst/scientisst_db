part of 'scientisst_db.dart';

class ObjectId {
  String _id;

  int _timestamp;
  int _randomValue;
  int _counter;

  ObjectId([String hexCode]) {
    if (hexCode == null) {
      _timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000);
      _randomValue = Random().nextInt(32) - 1;
      _counter = ScientISSTdb.instance._counter;
      _id = _timestamp.toRadixString(16).padLeft(8, '0') +
          _randomValue.toRadixString(16).padLeft(10, '0') +
          _counter.toRadixString(16).padLeft(6, '0');
    } else {
      assert(hexCode.length == 24);

      _timestamp = int.parse(hexCode.substring(0, 8), radix: 16);
      assert(timestamp.isBefore(DateTime.now()));

      _randomValue = int.parse(hexCode.substring(8, 18), radix: 16);
      assert(_randomValue < 32);

      _counter = int.parse(hexCode.substring(18), radix: 16);
      assert(counter < 8);
    }
  }

  String get id {
    return _id;
  }

  DateTime get timestamp {
    return DateTime.fromMillisecondsSinceEpoch(_timestamp * 1000);
  }

  int get randomValue {
    return _randomValue;
  }

  int get counter {
    return _counter;
  }
}
