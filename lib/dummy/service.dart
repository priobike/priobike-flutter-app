import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:priobike/logging/logger.dart';

class Dummy with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("Dummy");

  var text = "";

  /// Fetch the weather for the given location.
  Future<void> fetch() async {
    log.i("Fetched dummy data.");
    text = "${text}Hello World!";
    notifyListeners();
  }
}
