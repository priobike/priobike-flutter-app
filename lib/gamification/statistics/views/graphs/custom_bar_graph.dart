import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// This widget displays a simple bar graph for given yValues.
class CustomBarGraph extends StatelessWidget {
  /// Function which returns title widgets for the x axis.
  final Widget Function(double value, TitleMeta meta) getTitlesX;

  /// Function which handles a user tap on the graph. If the user tapped a bar, the index is not null.
  final Function(int? index) onTap;

  /// The displayed y values of the bars.
  final List<double> yValues;

  /// The preffered width of the bars.
  final double barWidth;

  /// Index of a bar that should be marked as selected.
  final int? selectedBar;

  /// Color of the displayed bars.
  final Color barColor;

  const CustomBarGraph({
    Key? key,
    required this.getTitlesX,
    required this.onTap,
    required this.yValues,
    required this.barWidth,
    this.selectedBar,
    required this.barColor,
  }) : super(key: key);

  /// Create bar from x and y value.
  BarChartGroupData createBar({required int x, bool? selected, required double y, double width = 20}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: (selected ?? true) ? barColor : barColor.withOpacity(0.25),
          width: width,
        ),
      ],
    );
  }

  /// Get list of bars according to the given values.
  List<BarChartGroupData> getBars() {
    return yValues
        .mapIndexed((i, d) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: d,
                  color: ((selectedBar == null ? null : (selectedBar == i)) ?? true)
                      ? barColor
                      : barColor.withOpacity(0.25),
                  width: barWidth,
                ),
              ],
            ))
        .toList();
  }

  /// Get fitting max value for a given list of values.
  static double getFittingMax(List<double> values) {
    if (values.isEmpty) return 0;
    var num = values.max;
    if (num == 0) return 1;
    if (num <= 5) return num;
    if (num <= 10) return num.ceilToDouble();
    if (num <= 50) return roundUpToInterval(num, 5);
    if (num <= 100) return roundUpToInterval(num, 10);
    return roundUpToInterval(num, 50);
  }

  /// Round a given double up to a given interval.
  static double roundUpToInterval(double num, int interval) {
    return interval * (num / interval).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
              handleBuiltInTouches: false,
              touchCallback: (p0, p1) {
                if (p0 is FlTapUpEvent) {
                  onTap(p1?.spot?.touchedBarGroupIndex);
                }
              },
              touchExtraThreshold: const EdgeInsets.all(8)),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  axisSide: AxisSide.left,
                  space: 4,
                  child: Text(
                    meta.formattedValue,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                reservedSize: 30,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                getTitlesWidget: getTitlesX,
                showTitles: true,
                reservedSize: 27,
              ),
            ),
          ),
          maxY: getFittingMax(yValues),
          gridData: FlGridData(drawVerticalLine: false),
          barGroups: getBars(),
        ),
        swapAnimationDuration: Duration.zero,
      ),
    );
  }
}
