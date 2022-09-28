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
