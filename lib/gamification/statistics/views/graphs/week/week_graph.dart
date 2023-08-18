import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/views/utils.dart';
import 'package:priobike/gamification/statistics/views/graphs/custom_bar_graph.dart';

/// Displayes ride statistics for a single week. The data is obtained from a given [WeekGraphViewModel].
class WeekStatsGraph extends StatelessWidget {
  final Function() tabHandler;

  final WeekGraphViewModel viewModel;

  const WeekStatsGraph({
    Key? key,
    required this.tabHandler,
    required this.viewModel,
  }) : super(key: key);

  Widget getTitlesX(double value, TitleMeta meta, BuildContext context, TextStyle style) {
    var today = DateTime.now();
    var todayIndex = today.difference(viewModel.startDay).inDays;
    String text = StatUtils.getWeekStr(value.toInt());
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Column(
        children: [
          Text(
            text,
            style: todayIndex == value ? style.copyWith(fontWeight: FontWeight.bold) : style,
          ),
          todayIndex != value
              ? const SizedBox.shrink()
              : SizedBox.fromSize(
                  size: const Size(16, 3),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(3)),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomBarGraph(
      barWidth: 20,
      barColor: Theme.of(context).colorScheme.primary,
      selectedBar: viewModel.selectedIndex,
      yValues: viewModel.yValues,
      getTitlesX: (value, meta) => getTitlesX(value, meta, context, Theme.of(context).textTheme.labelMedium!),
      onTap: (int? index) async {
        if (viewModel.selectedIndex == null && index == null) await tabHandler();
        viewModel.setSelectedIndex(index);
      },
    );
  }
}
