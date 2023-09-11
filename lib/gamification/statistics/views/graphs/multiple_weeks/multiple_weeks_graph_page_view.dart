import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/gamification/statistics/services/stats_view_model.dart';
import 'package:priobike/gamification/statistics/views/graphs/multiple_weeks/multiple_weeks_graph.dart';
import 'package:priobike/gamification/statistics/views/graphs/ride_graphs_page_view.dart';

/// This widget shows detailed statistics for the last 5  5-week intervals, using the [RideGraphsPageView] widget.
class MultipleWeeksGraphsPageView extends StatelessWidget {
  final StatisticsViewModel viewModel;

  final int weeksPerGraph;

  const MultipleWeeksGraphsPageView({
    Key? key,
    required this.viewModel,
    required this.weeksPerGraph,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<ListOfRideStats<WeekStats>> displayedStats = [];
    var allWeeks = List.from(viewModel.weeks);
    while (allWeeks.length >= weeksPerGraph) {
      List<WeekStats> weeks = [];
      for (int i = 0; i < weeksPerGraph; i++) {
        weeks.insert(0, allWeeks.removeLast());
      }
      displayedStats.add(ListOfRideStats<WeekStats>(weeks));
    }
    if (displayedStats.isEmpty) return const SizedBox.shrink();
    return RideGraphsPageView(
      graphs: displayedStats
          .map(
            (element) => MultipleWeeksStatsGraph(weeks: element.list),
          )
          .toList(),
      displayedStats: displayedStats,
    );
  }
}
