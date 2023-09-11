import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/gamification/statistics/views/graphs/ride_stats_graph.dart';

class WeekStatsGraph extends StatelessWidget {
  final WeekStats week;

  const WeekStatsGraph({Key? key, required this.week}) : super(key: key);

  Widget getTitlesX(double value, TitleMeta meta, TextStyle style) {
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
      getTitlesX: (value, meta) => getTitlesX(value, meta, Theme.of(context).textTheme.labelMedium!),
      displayedStats: week,
    );
  }
}
