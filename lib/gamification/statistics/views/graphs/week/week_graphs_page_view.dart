import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/services/stats_view_model.dart';
import 'package:priobike/gamification/statistics/views/graphs/ride_graphs_page_view.dart';
import 'package:priobike/gamification/statistics/views/graphs/week/week_graph.dart';

/// This widget shows detailed statistics for the last 10 weeks, using the [RideGraphsPageView] widget.
class WeekGraphsPageView extends StatelessWidget {
  final StatisticsViewModel viewModel;

  const WeekGraphsPageView({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (viewModel.weeks.isEmpty) return const SizedBox.shrink();
    var reverseWeeks = viewModel.weeks.reversed.toList();
    return RideGraphsPageView(
      graphs: reverseWeeks.map((week) => WeekStatsGraph(week: week)).toList(),
      displayedStats: reverseWeeks,
    );
  }
}
