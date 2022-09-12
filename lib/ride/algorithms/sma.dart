/// Simple moving average.
class SMA {
  /// The length of the moving average.
  final int k;

  /// The values of the moving average.
  final List<double> values = [];

  /// The current sum.
  double sum = 0;

  SMA({required this.k});

  /// Add a new value to the moving average.
  double next(double value) {
    values.add(value);
    sum += value;
    if (values.length > k) {
      sum -= values.removeAt(0);
    }
    return sum / values.length;
  }
}

/// A moving average for rotations.
/// In comparison to a normal moving average, this one takes the shortest path
/// between two angles into account. This is important for rotations, as the
/// shortest path between 0 and 360 degrees is 0 degrees.
class RotationSMA {
  /// The length of the moving average.
  final int k;

  /// The values of the moving average.
  final List<double> values = [];

  /// The current sum.
  double sum = 0;

  RotationSMA({required this.k});

  /// Add a new value to the moving average.
  double next(double value) {
    // If the value jumps over 360 degrees or below 0 degrees, we need to
    // calculate the shortest path.
    if (values.isNotEmpty && (value - values.last).abs() > 180) {
      if (value > values.last) {
        value -= 360;
      } else {
        value += 360;
      }
    }
    values.add(value);
    sum += value;
    if (values.length > k) {
      sum -= values.removeAt(0);
    }
    return sum / values.length;
  }
}
