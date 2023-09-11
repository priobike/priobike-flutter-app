import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/gamification/statistics/views/graphs/ride_stats_graph.dart';

class MonthStatsGraph extends StatelessWidget {
  final MonthStats month;

  const MonthStatsGraph({Key? key, required this.month}) : super(key: key);

  Widget getTitlesX(double value, TitleMeta meta, TextStyle style) {
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
      getTitlesX: (value, meta) => getTitlesX(value, meta, Theme.of(context).textTheme.labelMedium!),
      displayedStats: month,
    );
  }
}
