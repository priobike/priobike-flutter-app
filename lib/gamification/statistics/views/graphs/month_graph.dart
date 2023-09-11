import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/gamification/statistics/views/graphs/ride_stats_graph.dart';

/// Graph which displays the data for a given month.
class MonthStatsGraph extends StatelessWidget {
  /// The stats of the given month.
  final MonthStats month;

  const MonthStatsGraph({Key? key, required this.month}) : super(key: key);

  /// Label the x axis by adding the day value to every fifth day.
  Widget _getTitlesX(double value, TitleMeta meta, TextStyle style) {
    if ((value + 1) % 5 > 0) return const SizedBox.shrink();
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(
        (value.toInt() + 1).toString(),
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RideStatsGraph(
      barWidth: 5,
      getTitlesX: (value, meta) => _getTitlesX(value, meta, Theme.of(context).textTheme.labelMedium!),
      displayedStats: month,
    );
  }
}
