import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/services/test.dart';

/// This widget displays a simple bar graph for given yValues.
class CustomBarGraph extends StatelessWidget {
  /// Function which returns title widgets for the x axis.
  final Widget Function(double value, TitleMeta meta) getTitlesX;

  /// Function which handles a user tap on the graph. If the user tapped a bar, the index is not null.
  final Function(int? index) onTap;

  final ListOfRideStats rideStats;

  final StatType statType;

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
    required this.rideStats,
    required this.barWidth,
    required this.barColor,
    this.selectedBar,
    required this.statType,
  }) : super(key: key);

  /// Get list of bars according to the given values.
  List<BarChartGroupData> getBars(Color onBackground) {
    return rideStats.list.mapIndexed((i, stat) {
      var value = stat.getStatFromType(statType);
      var selected = selectedBar != null && selectedBar == i;
      var goalForBar = stat.getGoalFromType(statType);
      var goalReached = goalForBar == null ? true : value >= goalForBar;
      var barColorOpacity = goalReached ? 1.0 : 0.4;
      if (selectedBar != null) {
        barColorOpacity = selected ? 1.0 : 0.2;
      }

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            color: barColor.withOpacity(barColorOpacity),
            width: barWidth,
            borderSide: selected ? BorderSide(color: onBackground.withOpacity(0.5), width: 1) : null,
            backDrawRodData: goalReached
                ? null
                : BackgroundBarChartRodData(
                    show: true,
                    toY: goalForBar,
                    color: onBackground.withOpacity(0.05),
                  ),
          ),
        ],
      );
    }).toList();
  }

  /// Get fitting max value for a given list of values.
  double getFittingMax() {
    var num = rideStats.getMaxForType(statType);
    if (num == 0) return 1;
    if (num <= 5) return num;
    if (num <= 10) return num.ceilToDouble();
    if (num <= 50) return roundUpToInterval(num, 5);
    if (num <= 100) return roundUpToInterval(num, 10);
    return roundUpToInterval(num, 50);
  }

  /// Round a given double up to a given interval.
  static double roundUpToInterval(double num, int interval) => interval * (num / interval).ceilToDouble();

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
          maxY: getFittingMax(),
          gridData: FlGridData(drawVerticalLine: false),
          barGroups: getBars(Theme.of(context).colorScheme.onBackground),
        ),
        swapAnimationDuration: Duration.zero,
      ),
    );
  }
}
