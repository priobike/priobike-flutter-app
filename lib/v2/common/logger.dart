import 'package:ansicolor/ansicolor.dart';
import 'package:intl/intl.dart';

/// A logging class for the app.
class Logger {
  /// The messages of the app log.
  static List<String> db = [];

  /// The label for this logger.
  String label;

  /// Create a logger with a given label.
  Logger(this.label);

  /// Dispatch an INFO message.
  i(msg) {
    // ignore: avoid_print
    print('[INFO][${DateTime.now().toString()} $label] $msg');
    addToLog(msg);
  }

  /// Dispatch a WARN message.
  w(msg) {
    AnsiPen pen = AnsiPen()..yellow();
    // ignore: avoid_print
    print(pen('[WARN][${DateTime.now().toString()} $label] $msg'));
    addToLog(msg);
  }

  /// Dispatch an ERROR message.
  e(msg) {
    AnsiPen pen = AnsiPen()..red();
    // ignore: avoid_print
    print(pen('[ERROR][${DateTime.now().toString()} $label] $msg'));
    addToLog(msg);
  }

  /// Add the message to log.
  addToLog(msg) {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final String formattedDateTime = formatter.format(now);
    db.add('[$formattedDateTime] $msg');
  }
}
