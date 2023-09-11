import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/gamification/statistics/views/graphs/ride_stats_graph.dart';

/// Graph which displays the data for a given list of weeks. 
class MultipleWeeksStatsGraph extends StatelessWidget {
  /// The week stats corresponding to the weeks to be displayed. 
  final List<WeekStats> weeks;

  const MultipleWeeksStatsGraph({Key? key, required this.weeks}) : super(key: key);

  /// Label the x axis by adding the monday date to each week bar.
  Widget getTitlesX(double value, TitleMeta meta, TextStyle style) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(
        StringFormatter.getShortDateStr(weeks.elementAt(value.toInt()).mondayDate),
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var listOfWeeks = ListOfRideStats<WeekStats>(weeks);
    return RideStatsGraph(
      barWidth: 30,
      getTitlesX: (value, meta) => getTitlesX(value, meta, Theme.of(context).textTheme.labelSmall!),
      displayedStats: listOfWeeks,
    );
  }
}
