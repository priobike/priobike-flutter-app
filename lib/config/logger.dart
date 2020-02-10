import 'package:ansicolor/ansicolor.dart';

class Logger {
  String label;

  Logger(this.label);

  i(msg) {
    print('[$label] $msg');
  }

  w(msg) {
    AnsiPen pen = new AnsiPen()..yellow();
    print(pen('[$label] $msg'));
  }

  e(msg) {
    AnsiPen pen = new AnsiPen()..red();
    print(pen('[$label] $msg'));
  }
}
