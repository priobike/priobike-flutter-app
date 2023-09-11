import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/gamification/statistics/models/stat_type.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/main.dart';

class RideStatsGraph extends StatefulWidget {
  /// Function which returns title widgets for the x axis.
  final Widget Function(double value, TitleMeta meta) getTitlesX;

  /// The stats displayed by the graph.
  final ListOfRideStats displayedStats;

  /// The preffered width of the bars.
  final double barWidth;

  /// Color of the displayed bars.
  final Color barColor;

  const RideStatsGraph({
    Key? key,
    required this.getTitlesX,
    required this.displayedStats,
    required this.barWidth,
    this.barColor = CI.blue,
  }) : super(key: key);

  @override
  State<RideStatsGraph> createState() => _RideStatsGraphState();
}

class _RideStatsGraphState extends State<RideStatsGraph> {
  late StatisticService statsService;

  StatType get type => statsService.rideInfo;

  int? get selectedIndex => widget.displayedStats.isDayInList(statsService.selectedDate);

  @override
  void initState() {
    statsService = getIt<StatisticService>();
    statsService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    statsService.removeListener(update);
    super.dispose();
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  /// Get list of bars according to the given values.
  List<BarChartGroupData> getBars(Color onBackground) {
    return widget.displayedStats.list.mapIndexed((i, stat) {
      var value = stat.getStatFromType(type);
      var selected = selectedIndex != null && selectedIndex == i;
      var goalForBar = stat.getGoalFromType(type);
      var goalReached = goalForBar == null ? true : value >= goalForBar;
      var barColorOpacity = goalReached ? 1.0 : 0.4;
      if (selectedIndex != null) barColorOpacity = selected ? 1.0 : 0.2;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            color: widget.barColor.withOpacity(barColorOpacity),
            width: widget.barWidth,
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
    var num = widget.displayedStats.getMaxForType(type);
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
                  var index = p1?.spot?.touchedBarGroupIndex;
                  if (index == null) {
                    statsService.setSelectedDate(null);
                    return;
                  } else {
                    var selectedElement = widget.displayedStats.list.elementAt(index);
                    if (selectedElement is DayStats) {
                      statsService.setSelectedDate(selectedElement.date);
                    } else if (selectedElement is WeekStats) {
                      statsService.setSelectedDate(selectedElement.mondayDate);
                    }
                  }
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
                getTitlesWidget: widget.getTitlesX,
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
