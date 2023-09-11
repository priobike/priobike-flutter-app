import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/colors.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/feature_view.dart';
import 'package:priobike/gamification/common/views/feature_card.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/statistics/services/stats_view_model.dart';
import 'package:priobike/gamification/statistics/views/graphs/month_graph.dart';
import 'package:priobike/gamification/statistics/views/graphs/multiple_weeks_graph.dart';
import 'package:priobike/gamification/statistics/views/graphs/week_graph.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/gamification/statistics/views/route_stats.dart';
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
  late final TabController tabController = TabController(length: 4, vsync: this);

  late final StatisticsViewModel viewModel;

  late StatisticService _statsService;

  @override
  void initState() {
    _statsService = getIt<StatisticService>();
    _statsService.addListener(update);
    initViewModel();
    super.initState();
  }

  @override
  void dispose() {
    _statsService.removeListener(update);
    tabController.dispose();
    pageController.dispose();
    viewModel.removeListener(update);
    viewModel.dispose();
    super.dispose();
  }

  /// Initialize view model to hold data for roughly the last 5 weeks, which is enough for the graphs.
  void initViewModel() {
    var today = DateTime.now();
    today = DateTime(today.year, today.month, today.day);
    var statsStartDate = today.subtract(const Duration(days: 5 * DateTime.daysPerWeek));
    viewModel = StatisticsViewModel(startDate: statsStartDate, endDate: today);
    viewModel.addListener(update);
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    var newIndex = getIt<StatisticService>().statInterval.index;
    if (pageController.hasClients && (newIndex - (pageController.page ?? newIndex)).abs() >= 1) {
      pageController.animateToPage(
        newIndex,
        duration: ShortDuration(),
        curve: Curves.ease,
      );
      return;
    }
    if (mounted) setState(() {});
  }

  Widget getGraphWithTitle({required String title, required Widget graph}) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Row(
          children: [
            const SmallHSpace(),
            BoldSubHeader(
              text: title,
              context: context,
              textAlign: TextAlign.start,
            ),
          ],
        ),
        Expanded(
          child: IgnorePointer(child: graph),
        ),
      ],
    );
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
              SizedBox(
                height: 200,
                child: PageView(
                  controller: pageController,
                  clipBehavior: Clip.hardEdge,
                  onPageChanged: (int index) => setState(() {
                    // Update tab controller index to update the indicator.
                    tabController.index = index;
                    getIt<StatisticService>().setStatInterval(
                      StatInterval.values[min(index, StatInterval.values.length - 1)],
                    );
                  }),
                  children: [
                    getGraphWithTitle(
                      title: 'Diese Woche',
                      graph: WeekStatsGraph(week: viewModel.weeks.last),
                    ),
                    getGraphWithTitle(
                      title: 'Dieser Monat',
                      graph: MonthStatsGraph(month: viewModel.months.last),
                    ),
                    getGraphWithTitle(
                      title: '${viewModel.weeks.length} Wochen Rückblick',
                      graph: MultipleWeeksStatsGraph(weeks: viewModel.weeks),
                    ),
                    RouteStatistics(viewModel: viewModel),
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
