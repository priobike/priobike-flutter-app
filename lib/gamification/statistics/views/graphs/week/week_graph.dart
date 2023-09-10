import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/services/test.dart';
import 'package:priobike/gamification/statistics/views/graphs/custom_bar_graph.dart';

/// Displayes ride statistics for a single week. The data is obtained from a given [WeekStatsViewModel].
class WeekStatsGraph extends StatelessWidget {
  final Function(DateTime? date) onSelection;

  final WeekStats week;

  final StatType type;

  final int? selectedIndex;

  const WeekStatsGraph({
    Key? key,
    required this.onSelection,
    required this.week,
    required this.type,
    required this.selectedIndex,
  }) : super(key: key);

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
    return CustomBarGraph(
      barWidth: 20,
      barColor: Theme.of(context).colorScheme.primary,
      selectedBar: selectedIndex,
      getTitlesX: (value, meta) => getTitlesX(value, meta, Theme.of(context).textTheme.labelMedium!),
      onTap: (i) => onSelection(i == null ? null : week.list.elementAt(i).date),
      rideStats: week,
      statType: type,
    );
  }
}
