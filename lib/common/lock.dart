import 'dart:async';
import 'package:flutter/material.dart';

/// Run action only if the last action ran before the given milliseconds.
class Lock {
  /// The preferred interval.
  final int milliseconds;

  /// The currently running timer.
  Timer? timer;

  Lock({required this.milliseconds});

  run(VoidCallback action) {
    if(timer == null || !(timer!.isActive)) {
      action();
      timer = Timer(Duration(milliseconds: milliseconds), () {});
    }
  }
}