import 'dart:async';
import 'package:flutter/material.dart';

/// Run action only after no new action happened in the given interval.
class Debouncer {
  /// The preferred interval.
  final int milliseconds;

  /// The currently running timer.
  Timer? timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    timer?.cancel();
    timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}