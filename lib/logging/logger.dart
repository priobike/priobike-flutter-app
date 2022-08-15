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
    // ignore: avoid_print
    print('[WARN][${DateTime.now().toString()} $label] $msg');
    addToLog(msg);
  }

  /// Dispatch an ERROR message.
  e(msg) {
    // ignore: avoid_print
    print('[ERROR][${DateTime.now().toString()} $label] $msg');
    addToLog(msg);
  }

  /// Add the message to log.
  addToLog(msg) {
    final DateTime now = DateTime.now();
    db.add('[${now.toIso8601String()}] $msg');
  }
}
