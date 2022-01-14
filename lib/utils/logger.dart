import 'package:ansicolor/ansicolor.dart';
import 'package:intl/intl.dart';

class Logger {
  static List<String> db = [];

  String label;

  Logger(this.label);

  i(msg) {
    // ignore: avoid_print
    print('[${DateTime.now().toString()} $label] $msg');
    addToLog(msg);
  }

  w(msg) {
    AnsiPen pen = AnsiPen()..yellow();
    // ignore: avoid_print
    print(pen('[${DateTime.now().toString()} $label] $msg'));
    addToLog(msg);
  }

  e(msg) {
    AnsiPen pen = AnsiPen()..red();
    // ignore: avoid_print
    print(pen('[${DateTime.now().toString()} $label] $msg'));
    addToLog(msg);
  }

  addToLog(msg) {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String formattedDateTime = formatter.format(now);
    db.add('[$formattedDateTime] $msg');
  }
}
