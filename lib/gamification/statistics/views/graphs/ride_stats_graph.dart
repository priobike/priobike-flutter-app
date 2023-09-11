import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/gamification/statistics/models/stat_type.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/main.dart';

/// This widget displays a given list of ride stats in a graph.
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
  /// The stat service to get the current selected stat type to be displayed.
  late StatisticService _statsService;

  /// Index of the selected bar or null, if none is selected.
  int? _selectedIndex;

  /// Stat type to be displayed.
  StatType get _type => _statsService.selectedType;

  @override
  void initState() {
    _statsService = getIt<StatisticService>();
    _statsService.addListener(update);
    _selectedIndex = widget.displayedStats.isDayInList(_statsService.selectedDate);
    super.initState();
  }

  @override
  void dispose() {
    _statsService.removeListener(update);
    super.dispose();
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  /// Get list of bars according to the given values and goal values.
  List<BarChartGroupData> _getBars() {
    var list = widget.displayedStats.list;
    return list.mapIndexed((i, stat) {
      var value = stat.getStatFromType(_type);
      var selected = _selectedIndex != null && _selectedIndex == i;
      var goalForBar = stat.getGoalFromType(_type);
      var goalReached = goalForBar == null ? true : value >= goalForBar;
      var barColorOpacity = goalReached ? 1.0 : 0.4;
      if (_selectedIndex != null) barColorOpacity = selected ? 1.0 : 0.2;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            color: widget.barColor.withOpacity(barColorOpacity),
            width: widget.barWidth,
            borderSide: selected
                ? BorderSide(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5), width: 1)
                : null,
            backDrawRodData: goalReached
                ? null
                : BackgroundBarChartRodData(
                    show: true,
                    toY: goalForBar,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
                  ),
          ),
        ],
      );
    }).toList();
  }

  /// Get max value for the stats to be displayed, rounded to a fitting interval.
  double _getRoundedMax() {
    var num = widget.displayedStats.getMaxForType(_type);
    if (num == 0) return 1;
    if (num <= 5) return num;
    if (num <= 10) return num.ceilToDouble();
    if (num <= 50) return _roundUpToInterval(num, 5);
    if (num <= 100) return _roundUpToInterval(num, 10);
    if (num <= 200) return _roundUpToInterval(num, 25);
    if (num <= 500) return _roundUpToInterval(num, 50);
    return _roundUpToInterval(num, 100);
  }

  /// Round a given double up to a given interval.
  double _roundUpToInterval(double num, int interval) => interval * (num / interval).ceilToDouble();

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
                    return _statsService.selectDate(null);
                  } else {
                    var selectedElement = widget.displayedStats.list.elementAt(index);
                    if (selectedElement is DayStats) {
                      _statsService.selectDate(selectedElement.date);
                    } else if (selectedElement is WeekStats) {
                      _statsService.selectDate(selectedElement.mondayDate);
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
          maxY: _getRoundedMax(),
          gridData: FlGridData(drawVerticalLine: false),
          barGroups: _getBars(),
        ),
        swapAnimationDuration: Duration.zero,
      ),
    );
  }
}
