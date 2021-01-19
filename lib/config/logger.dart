import 'package:ansicolor/ansicolor.dart';
import 'package:intl/intl.dart';

class Logger {
  static List<String> db = [];

  String label;

  Logger(this.label);

  i(msg) {
    print('[${DateTime.now().toString()} $label] $msg');
    addToLog(msg);
  }

  w(msg) {
    AnsiPen pen = new AnsiPen()..yellow();
    print(pen('[${DateTime.now().toString()} $label] $msg'));
    addToLog(msg);
  }

  e(msg) {
    AnsiPen pen = new AnsiPen()..red();
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
