import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  /// Returns a string describing how much time the user has left for a challenge.
  String _getTimeLeftStr(DateTime date) {
    var timeLeft = date.difference(DateTime.now());
    if (timeLeft.isNegative) return 'Zeit abgelaufen';
    var result = '';
    var daysLeft = timeLeft.inDays;
    if (daysLeft > 0) result += '$daysLeft ${daysLeft > 1 ? 'Tage' : 'Tag'} ';
    var formatter = NumberFormat('00');
    result += '${formatter.format(timeLeft.inHours % 24)}:${formatter.format(timeLeft.inMinutes % 60)}h';
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _getTimeLeftStr(widget.timestamp),
      style: widget.style ??
          Theme.of(context).textTheme.headlineMedium!.merge(TextStyle(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
              )),
    );
  }
}
