import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/colors.dart';
import 'package:priobike/gamification/common/custom_game_icons.dart';
import 'package:priobike/gamification/common/views/tutorial_page.dart';
import 'package:priobike/gamification/hub/views/feature_card.dart';
import 'package:priobike/gamification/hub/views/hub_card.dart';
import 'package:priobike/gamification/settings/services/settings_service.dart';
import 'package:priobike/gamification/statistics/views/graphs/compact_labled_graph.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/views/graphs/month/month_graph.dart';
import 'package:priobike/gamification/statistics/views/graphs/multiple_weeks/multiple_weeks_graph.dart';
import 'package:priobike/gamification/statistics/views/graphs/week/week_graph.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/gamification/statistics/views/statistics_tutorial.dart';
import 'package:priobike/gamification/statistics/views/statistics_view.dart';
import 'package:priobike/main.dart';

class RideStatisticsCard extends StatelessWidget {
  /// Open view function from parent widget is required, to animate the hub cards away when opening the stats view.
  final Future Function(Widget view) openView;

  const RideStatisticsCard({Key? key, required this.openView}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FeatureCard(
      featureKey: GameSettingsService.gameFeatureStatisticsKey,
      featureEnabledWidget: StatisticsEnabeldCard(openView: openView),
      featureDisabledWidget: StatisticsDisabledCard(openView: openView),
    );
  }
}

/// A gamification hub card which displays graphs containing statistics of the users' rides.
class StatisticsEnabeldCard extends StatefulWidget {
  /// Open view function from parent widget is required, to animate the hub cards away when opening the stats view.
  final Future Function(Widget view) openView;

  const StatisticsEnabeldCard({Key? key, required this.openView}) : super(key: key);

  @override
  State<StatisticsEnabeldCard> createState() => _StatisticsEnabeldCardState();
}

class _StatisticsEnabeldCardState extends State<StatisticsEnabeldCard> with SingleTickerProviderStateMixin {
  // Controller for the page view displaying the different statistics.
  final PageController pageController = PageController();

  /// Controller which connects the tab indicator to the page view.
  late final TabController tabController = TabController(length: 3, vsync: this);

  /// View models of the displayed graphs. They provide the graphs with their corresponding data.
  final List<GraphViewModel> graphViewModels = [];

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

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

  /// Initialize view models such that the graphs show the data of the current week, month, and the last 5 weeks.
  void initGraphViewModels() {
    var today = DateTime.now();
    today = DateTime(today.year, today.month, today.day);
    var thisWeeksStart = today.subtract(Duration(days: today.weekday - 1));
    graphViewModels.add(WeekGraphViewModel(thisWeeksStart));
    graphViewModels.add(MonthGraphViewModel(today.year, today.month));
    graphViewModels.add(MultipleWeeksGraphViewModel(thisWeeksStart, 5));

    /// Listen to changes in the viewmodels and rebuilt widget if necessary.
    for (var viewModel in graphViewModels) {
      viewModel.startStreams();
      viewModel.addListener(update);
    }
  }

  /// Handles a tap on the card which is not recognized as an interaction with the graphs.
  Future<void> onTap() async {
    await widget.openView(const StatisticsView());
    var newIndex = getIt<StatisticService>().statInterval.index;
    if (pageController.hasClients) pageController.jumpToPage(newIndex);
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
                getIt<StatisticService>().setStatInterval(StatInterval.values[index]);
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

/// Info widget which is shown, if the user hasn't enabled the statistics.
class StatisticsDisabledCard extends StatelessWidget {
  final Future Function(Widget view) openView;

  const StatisticsDisabledCard({Key? key, required this.openView}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GameHubCard(
      onTap: () async {
        openView(const StatisticsTutorial());
      },
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: BoldSubHeader(
                        text: 'Deine Fahrtstatistiken',
                        context: context,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SmallHSpace(),
                    SizedBox(
                      width: 96,
                      height: 80,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Transform.rotate(
                              angle: 0,
                              child: const Icon(
                                Icons.query_stats,
                                size: 64,
                                color: Medals.silver,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Transform.rotate(
                              angle: 0,
                              child: const Icon(
                                Icons.bar_chart,
                                size: 64,
                                color: CI.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
