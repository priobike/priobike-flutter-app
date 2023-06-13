import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// A logging class for the app.
class Logger {
  /// The messages of the app log.
  static List<String> db = [];

  /// The label for this logger.
  String label;

  /// Create a logger with a given label.
  Logger(this.label);

  /// The current log cache.
  static LogCache? cache;

  /// Whether the cache is being created currently.
  static bool creatingCache = false;

  /// The queued messages (while the cache is being created).
  static List<String> queuedMessages = [];

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
    addToLogCache('[${now.toIso8601String()}] $msg');
  }

  /// Persist the log to the device.
  Future<void> addToLogCache(String msg) async {
    if (cache == null && !creatingCache) {
      createCache(msg);
      return;
    }
    if (cache == null && creatingCache) {
      queuedMessages.add(msg);
      return;
    }
    if (queuedMessages.isNotEmpty) {
      for (final queuedMessage in queuedMessages) {
        await cache!.add(queuedMessage);
      }
      queuedMessages.clear();
    }
    await cache!.add(msg);
  }

  /// Create the cache.
  Future<void> createCache(String msg) async {
    creatingCache = true;
    await printOldLogs();
    final dir = await getApplicationDocumentsDirectory();
    cache = LogCache(
      file: File('${dir.path}/logs/logs.txt'),
    );
    await cache!.add(msg);
    creatingCache = false;
  }

  /// Print the old logs.
  Future<void> printOldLogs() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/logs/logs.txt');
    if (!await file.exists()) return;
    showLog("\n\n");
    showLog("=========================================");
    showLog("\n");
    showLog("Printing old logs");
    showLog("\n");
    showLog("=========================================");
    showLog("\n\n");
    final lines = await file.readAsLines();
    for (final line in lines) {
      showLog(line);
    }
    showLog("\n\n");
    showLog("=========================================");
    showLog("\n");
    showLog("End of old logs");
    showLog("\n");
    showLog("=========================================");
    showLog("\n\n");

    await file.delete();
  }

  /// Show the log.
  void showLog(msg) {
    db.add(msg);
    // ignore: avoid_print
    print(msg);
  }
}

class LogCache {
  /// The currently pending lines.
  List<String> lines;

  /// The file reference.
  File file;

  /// The maximum number of lines to cache.
  static const maxLines = 1;

  LogCache({
    required this.file,
  }) : lines = [];

  /// Add a line to the cache.
  Future<void> add(String line) async {
    lines.add(line);
    if (lines.length >= maxLines) await flush();
  }

  /// Flush the cache.
  Future<void> flush() async {
    if (lines.isEmpty) return;
    // Create the file if it does not exist.
    var fileIsNew = false;
    if (!await file.exists()) {
      await file.create(recursive: true);
      fileIsNew = true;
    }
    // Flush the cache and write the data to the file.
    final txt = lines.join("\n");
    lines.clear();
    // If the file is not new, append a newline.
    if (!fileIsNew) await file.writeAsString("\n", mode: FileMode.append, flush: true);
    await file.writeAsString(txt, mode: FileMode.append, flush: true);
  }
}
