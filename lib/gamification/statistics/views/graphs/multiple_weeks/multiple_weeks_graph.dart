import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/services/test.dart';
import 'package:priobike/gamification/statistics/views/graphs/custom_bar_graph.dart';

/// Displayes ride statistics for a single week. The data is obtained from a given [MultipleWeeksStatsViewModel].
class MultipleWeeksStatsGraph extends StatelessWidget {
  final Function(DateTime? date) onSelection;

  final List<WeekStats> weeks;

  final StatType type;

  final int? selectedIndex;

  const MultipleWeeksStatsGraph({
    Key? key,
    required this.onSelection,
    required this.weeks,
    required this.type,
    required this.selectedIndex,
  }) : super(key: key);

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
    return CustomBarGraph(
      barColor: Theme.of(context).colorScheme.primary,
      barWidth: 30,
      selectedBar: selectedIndex,
      getTitlesX: (value, meta) => getTitlesX(value, meta, Theme.of(context).textTheme.labelSmall!),
      onTap: (i) => onSelection(i == null ? null : weeks.elementAt(i).mondayDate),
      rideStats: ListOfRideStats<WeekStats>(weeks),
      statType: type,
    );
  }
}
