class SpeedIsZeroException implements Exception {
  final String msg;

  const SpeedIsZeroException([this.msg]);

  @override
  String toString() => msg ?? 'SpeedIsZeroException';
}

class TooFarIntoTheFutureException implements Exception {
  final String msg;

  const TooFarIntoTheFutureException([this.msg]);

  @override
  String toString() => msg ?? 'TooFarIntoTheFutureException';
}


class TimeToPhaseIsZeroException implements Exception {
  final String msg;

  const TimeToPhaseIsZeroException([this.msg]);

  @override
  String toString() => msg ?? 'TimeToPhaseIsZeroException';
}


