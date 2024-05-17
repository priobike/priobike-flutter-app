import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:priobike/common/csv.dart';

/// A logging class for the app.
class Logger {
  /// The messages of the app log.
  static CSVCache? db;

  /// The label for this logger.
  String label;

  /// Create a logger with a given label.
  Logger(this.label);

  /// Dispatch an INFO message.
  i(msg) async => await addToLog('INFO', msg);

  /// Dispatch a WARN message.
  w(msg) async => await addToLog('WARN', msg);

  /// Dispatch an ERROR message.
  e(msg) async => await addToLog('ERROR', msg);

  /// Add the message to log.
  addToLog(level, msg) async {
    final now = DateTime.now();
    // ignore: avoid_print
    print('[$level][${now.toIso8601String()} $label] $msg');
    db?.add('${now.millisecondsSinceEpoch},$level,$label,$msg');
  }

  /// Ensure the logger is initialized.
  static init(bool enableLogPersistence) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/log.csv');
    if (!enableLogPersistence) {
      // Remove the file if it exists.
      if (await file.exists()) await file.delete();
      db = null;
      return;
    }
    db = CSVCache(
      header: 'timestamp,level,label,message',
      file: file,
      maxLines: 0, // Flush every message.
      maxFileLines: 5000, // Rotate the log every x lines.
    );
    final now = DateTime.now();
    // Read how many lines are in the log.
    final lines = (await db?.read() ?? '').split('\n');
    final msg = 'Logger initialized: ${lines.length - 1} messages in log.';
    const level = 'INFO';
    const label = 'Logger';
    // ignore: avoid_print
    print('[$level][${now.toIso8601String()} $label] $msg');
    db?.add('${now.millisecondsSinceEpoch},$level,$label,$msg');
  }

  /// Get the log contents.
  static Future<String> read() async {
    return await db?.read() ?? '';
  }
}
