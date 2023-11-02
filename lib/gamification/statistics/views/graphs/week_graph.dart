import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/gamification/statistics/views/graphs/ride_stats_graph.dart';

/// Graph which displays the data for a given week.
class WeekStatsGraph extends StatelessWidget {
  /// The stats corresponding to the displayed week.
  final WeekStats week;

  const WeekStatsGraph({Key? key, required this.week}) : super(key: key);

  /// Label the x axis by adding a short description of the days of the week.
  Widget _getTitlesX(double value, TitleMeta meta, TextStyle style) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(
        StringFormatter.getWeekStr(value.toInt()),
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RideStatsGraph(
      barWidth: 20,
      getTitlesX: (value, meta) => _getTitlesX(value, meta, Theme.of(context).textTheme.labelMedium!),
      displayedStats: week,
    );
  }
}
