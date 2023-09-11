import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/services/stats_view_model.dart';
import 'package:priobike/gamification/statistics/views/graphs/ride_graphs_page_view.dart';
import 'package:priobike/gamification/statistics/views/graphs/month/month_graph.dart';

/// This widget shows detailed statistics for the last 6 months, using the [RideGraphsPageView] widget.
class MonthGraphsPageView extends StatelessWidget {
  final StatisticsViewModel viewModel;

  const MonthGraphsPageView({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (viewModel.months.isEmpty) return const SizedBox.shrink();
    return RideGraphsPageView(
      graphs: viewModel.months.map((month) => MonthStatsGraph(month: month)).toList(),
      displayedStats: viewModel.months,
    );
  }
}
