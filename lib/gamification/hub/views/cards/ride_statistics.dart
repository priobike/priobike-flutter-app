import 'package:flutter/material.dart';
import 'package:priobike/gamification/hub/views/cards/hub_card.dart';
import 'package:priobike/gamification/statistics/graphs/compact_labled_graph.dart';
import 'package:priobike/gamification/statistics/graphs/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/graphs/month/month_graph.dart';
import 'package:priobike/gamification/statistics/graphs/multiple_weeks/multiple_weeks_graph.dart';
import 'package:priobike/gamification/statistics/graphs/week/week_graph.dart';
import 'package:priobike/gamification/statistics/views/statistics_view.dart';

/// A gamification hub card which displays graphs containing statistics of the users' rides.
class RideStatisticsCard extends StatefulWidget {
  final Function(Widget view) openView;

  const RideStatisticsCard({Key? key, required this.openView}) : super(key: key);

  @override
  State<RideStatisticsCard> createState() => _RideStatisticsCardState();
}

class _RideStatisticsCardState extends State<RideStatisticsCard> with SingleTickerProviderStateMixin {
  // Controller for the page view displaying the different statistics.
  final PageController pageController = PageController();

  /// Controller which connects the tab indicator to the page view.
  late final TabController tabController = TabController(length: 3, vsync: this);

  final List<GraphViewModel> graphViewModels = [];

  void update() => setState(() {});

  @override
  void initState() {
    initGraphViewModels();
    super.initState();
  }

  @override
  void dispose() {
    tabController.dispose();
    pageController.dispose();
    for (var viewModel in graphViewModels) {
      viewModel.endStreams();
    }
    super.dispose();
  }

  void initGraphViewModels() {
    var today = DateTime.now();
    today = DateTime(today.year, today.month, today.day);
    var thisWeeksStart = today.subtract(Duration(days: today.weekday - 1));
    graphViewModels.add(WeekGraphViewModel(thisWeeksStart));
    graphViewModels.add(MonthGraphViewModel(today.year, today.month));
    graphViewModels.add(MultipleWeeksGraphViewModel(thisWeeksStart, 5));
    for (var viewModel in graphViewModels) {
      viewModel.startStreams();
      viewModel.addListener(update);
    }
  }

  Future<void> onTap() async {
    widget.openView(const StatisticsView());
  }

  @override
  Widget build(BuildContext context) {
    return GameHubCard(
      onTap: onTap,
      content: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 224,
            child: PageView(
              controller: pageController,
              clipBehavior: Clip.hardEdge,
              onPageChanged: (int index) => setState(() {
                // Update tab controller index to update the indicator.
                tabController.index = index;
              }),
              children: [
                CompactGraph(
                  viewModel: graphViewModels[0],
                  title: 'Diese Woche',
                  graph: WeekStatsGraph(tabHandler: onTap, viewModel: graphViewModels[0] as WeekGraphViewModel),
                ),
                CompactGraph(
                  viewModel: graphViewModels[1],
                  title: 'Dieser Monat',
                  graph: MonthStatsGraph(tabHandler: onTap, viewModel: graphViewModels[1] as MonthGraphViewModel),
                ),
                CompactGraph(
                  viewModel: graphViewModels[2],
                  title: '5 Wochen Rückblick',
                  graph: MultipleWeeksStatsGraph(
                      tabHandler: onTap, viewModel: graphViewModels[2] as MultipleWeeksGraphViewModel),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TabPageSelector(
              controller: tabController,
              selectedColor: Theme.of(context).colorScheme.primary,
              indicatorSize: 6,
              borderStyle: BorderStyle.none,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
              key: GlobalKey(),
            ),
          ),
        ],
      ),
    );
  }
}
