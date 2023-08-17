import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/graphs/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/views/utils.dart';
import 'package:priobike/gamification/statistics/graphs/ride_graph.dart';

class MultipleWeeksStatsGraph extends StatelessWidget {
  final Function() tabHandler;

  final MultipleWeeksGraphViewModel viewModel;

  const MultipleWeeksStatsGraph({
    Key? key,
    required this.tabHandler,
    required this.viewModel,
  }) : super(key: key);

  Widget getTitlesX(double value, TitleMeta meta, BuildContext context, TextStyle style) {
    var today = DateTime.now();
    var difference = today.difference(viewModel.rideMap.keys.elementAt(value.toInt())).inDays;
    var todayInWeek = difference < 7;
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Column(
        children: [
          Text(
            StatUtils.getDateStr(viewModel.rideMap.keys.elementAt(value.toInt())),
            style: todayInWeek ? style.copyWith(fontWeight: FontWeight.bold) : style,
          ),
          !todayInWeek
              ? const SizedBox.shrink()
              : SizedBox.fromSize(
                  size: const Size(32, 3),
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
    return RideStatisticsGraph(
      maxY: StatUtils.getFittingMax(viewModel.yValues),
      barColor: Theme.of(context).colorScheme.primary,
      yValues: viewModel.yValues,
      barWidth: 30,
      selectedBar: viewModel.selectedIndex,
      getTitlesX: (value, meta) => getTitlesX(value, meta, context, Theme.of(context).textTheme.labelSmall!),
      handleBarToucH: (int? index) async {
        if (viewModel.selectedIndex == null && index == null) await tabHandler();
        viewModel.setSelectedIndex(index);
      },
    );
  }
}
