import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/services/test.dart';
import 'package:priobike/gamification/statistics/views/graphs/custom_bar_graph.dart';

/// Displayes ride statistics for a single month. The data is obtained from a given [MonthStatsViewModel].
class MonthStatsGraph extends StatelessWidget {
  final Function(DateTime? date) onSelection;

  final MonthStats month;

  final StatType type;

  final int? selectedIndex;

  const MonthStatsGraph({
    Key? key,
    required this.onSelection,
    required this.month,
    required this.type,
    required this.selectedIndex,
  }) : super(key: key);

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
    return CustomBarGraph(
      barColor: Theme.of(context).colorScheme.primary,
      barWidth: 5,
      selectedBar: selectedIndex,
      getTitlesX: (value, meta) => getTitlesX(value, meta, Theme.of(context).textTheme.labelMedium!),
      onTap: (i) => i == null ? null : month.list.elementAt(i).date,
      rideStats: month,
      statType: type,
    );
  }
}
