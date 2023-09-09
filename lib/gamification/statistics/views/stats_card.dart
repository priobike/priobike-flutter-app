import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/colors.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/feature_view.dart';
import 'package:priobike/gamification/common/views/feature_card.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/views/graphs/month/month_graph.dart';
import 'package:priobike/gamification/statistics/views/graphs/multiple_weeks/multiple_weeks_graph.dart';
import 'package:priobike/gamification/statistics/views/graphs/week/week_graph.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/gamification/statistics/views/stats_tutorial.dart';
import 'package:priobike/gamification/statistics/views/stats_page.dart';
import 'package:priobike/main.dart';

class RideStatisticsCard extends StatelessWidget {
  const RideStatisticsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const GamificationFeatureView(
      featureKey: GamificationUserService.gameFeatureStatisticsKey,
      featureEnabledWidget: StatisticsEnabeldCard(),
      featureDisabledWidget: StatisticsDisabledCard(),
    );
  }
}

/// A gamification hub card which displays graphs containing statistics of the users' rides.
class StatisticsEnabeldCard extends StatefulWidget {
  const StatisticsEnabeldCard({Key? key}) : super(key: key);

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

  late StatisticService _statsService;

  @override
  void initState() {
    _statsService = getIt<StatisticService>();
    _statsService.addListener(update);
    initGraphViewModels();
    super.initState();
  }

  @override
  void dispose() {
    _statsService.removeListener(update);
    tabController.dispose();
    pageController.dispose();
    for (var viewModel in graphViewModels) {
      viewModel.endStreams();
    }
    super.dispose();
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    var newIndex = getIt<StatisticService>().statInterval.index;
    if (pageController.hasClients && (newIndex - (pageController.page ?? newIndex)).abs() >= 1) {
      pageController.animateToPage(
        newIndex,
        duration: TinyDuration(),
        curve: Curves.ease,
      );
      return;
    }
    if (mounted) setState(() {});
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

  String getTitle(int index) {
    if (index == 0) return 'Diese Woche';
    if (index == 1) return 'Dieser Monat';
    if (index == 2) return '5 Wochen Rückblick';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return EnabledFeatureCard(
      featureKey: GamificationUserService.gameFeatureStatisticsKey,
      directionView: const StatisticsView(),
      content: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SmallHSpace(),
                  BoldSubHeader(
                    text: getTitle(tabController.index),
                    context: context,
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 200,
                child: PageView(
                    controller: pageController,
                    clipBehavior: Clip.hardEdge,
                    onPageChanged: (int index) => setState(() {
                          // Update tab controller index to update the indicator.
                          tabController.index = index;
                          getIt<StatisticService>().setStatInterval(StatInterval.values[index]);
                        }),
                    children: [
                      IgnorePointer(
                        child: WeekStatsGraph(viewModel: graphViewModels[0] as WeekGraphViewModel),
                      ),
                      IgnorePointer(
                        child: MonthStatsGraph(viewModel: graphViewModels[1] as MonthGraphViewModel),
                      ),
                      IgnorePointer(
                        child: MultipleWeeksStatsGraph(viewModel: graphViewModels[2] as MultipleWeeksGraphViewModel),
                      ),
                    ]),
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
        ],
      ),
    );
  }
}

/// Info widget which is shown, if the user hasn't enabled the statistics.
class StatisticsDisabledCard extends StatelessWidget {
  const StatisticsDisabledCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DisabledFeatureCard(
      introPage: const StatisticsTutorial(),
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
                                color: LevelColors.silver,
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
