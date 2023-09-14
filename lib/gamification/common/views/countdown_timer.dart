

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/utils.dart';

/// Timer which counts down to a certain timestamp and updates every second.
class CountdownTimer extends StatefulWidget {
  /// The timestamp to count down to.
  final DateTime timestamp;

  /// This field can be used to apply a specific style to the countdown text.
  final TextStyle? style;

  const CountdownTimer({Key? key, required this.timestamp, this.style}) : super(key: key);

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  /// Timer to update the widget periodically.
  Timer? _timer;

  @override
  void initState() {
    /// Create timer which updates the widget every second.
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => setState(() {}),
    );
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      StringFormatter.getTimeLeftStr(widget.timestamp),
      style: widget.style ??
          Theme.of(context).textTheme.headlineMedium!.merge(TextStyle(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
              )),
    );
  }
}
