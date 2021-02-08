part of 'scientisst_db.dart';

const MAXIMUM_RANDOM_START = 16777216; // 3 bytes - 24 bits
const MAXIMUM_RANDOM_END = 65536; // 2 bytes - 16 bits

class ObjectId {
  String _id;

  int _timestamp;
  String _randomValue;
  int _counter;

  ObjectId([String hexCode]) {
    if (hexCode == null) {
      _timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000);
      final int randomValueStart = Random().nextInt(MAXIMUM_RANDOM_START) - 1;
      final int randomValueEnd = Random().nextInt(MAXIMUM_RANDOM_END) - 1;
      String _randomValue = randomValueStart.toRadixString(16).padLeft(6, '0') +
          randomValueEnd.toRadixString(16).padLeft(4, '0');

      _counter = ScientISSTdb.instance._counter;
      _id = _timestamp.toRadixString(16).padLeft(8, '0') +
          _randomValue +
          _counter.toRadixString(16).padLeft(6, '0');
    } else {
      assert(hexCode.length == 24);

      _timestamp = int.parse(hexCode.substring(0, 8), radix: 16);
      assert(timestamp.isBefore(DateTime.now()));

      _randomValue = hexCode.substring(8, 18);
      final int randomValueStart =
          int.parse(hexCode.substring(8, 14), radix: 16);
      assert(randomValueStart < MAXIMUM_RANDOM_START);

      _counter = int.parse(hexCode.substring(18), radix: 16);
      assert(counter < MAXIMUM_COUNTER);
      _id = hexCode;
    }
  }

  String get id {
    return _id;
  }

  DateTime get timestamp {
    return DateTime.fromMillisecondsSinceEpoch(_timestamp * 1000);
  }

  String get randomValue {
    return _randomValue;
  }

  int get counter {
    return _counter;
  }
}
