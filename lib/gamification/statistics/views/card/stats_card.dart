import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/colors.dart';
import 'package:priobike/gamification/common/views/feature_card.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/common/views/map_background.dart';
import 'package:priobike/gamification/statistics/services/stats_view_model.dart';
import 'package:priobike/gamification/statistics/views/card/daily_overview.dart';
import 'package:priobike/gamification/statistics/views/graphs/month_graph.dart';
import 'package:priobike/gamification/statistics/views/graphs/multiple_weeks_graph.dart';
import 'package:priobike/gamification/statistics/views/graphs/week_graph.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/gamification/statistics/views/card/route_stats.dart';
import 'package:priobike/gamification/statistics/views/page/stats_page.dart';
import 'package:priobike/main.dart';

/// This card is displayed on the home view and holds all information and functionality of the statistics feature.
class RideStatisticsCard extends StatelessWidget {
  const RideStatisticsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GamificationFeatureCard(
      onEnabled: () {},
      featureKey: GamificationUserService.statisticsFeatureKey,
      featurePage: const StatisticsView(),
      featureEnabledContent: const StatisticsOverview(),
      featureDisabledContent: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
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
      ),
    );
  }
}

/// A page view displaying a reduced stat history of the user for only the recent weeks.
class StatisticsOverview extends StatefulWidget {
  const StatisticsOverview({Key? key}) : super(key: key);

  @override
  State<StatisticsOverview> createState() => _StatisticsOverviewState();
}

class _StatisticsOverviewState extends State<StatisticsOverview> with TickerProviderStateMixin {
  // Controller for the page view displaying the different pages.
  late final PageController _pageController = PageController();

  /// Controller which connects the tab indicator to the page view.
  late final TabController _tabController = TabController(length: 5, vsync: this);

  /// The view model holding the ride stats of the displayed data.
  late final StatisticsViewModel _viewModel;

  /// Service to get the current stat interval that should be displayed.
  late StatisticService _statsService;

  @override
  void initState() {
    _statsService = getIt<StatisticService>();
    _statsService.addListener(updatePage);
    _initViewModel();
    super.initState();
  }

  @override
  void dispose() {
    _statsService.removeListener(updatePage);
    _tabController.dispose();
    _pageController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  /// Initialize view model to hold data for roughly the last 5 weeks, which is enough for the graphs.
  void _initViewModel() {
    var today = DateTime.now();
    today = DateTime(today.year, today.month, today.day);
    var statsStartDate = today.subtract(const Duration(days: 5 * DateTime.daysPerWeek));
    _viewModel = StatisticsViewModel(startDate: statsStartDate, endDate: today);
    _viewModel.addListener(update);
  }

  void updatePage() {
    var newIndex = _statsService.statInterval.index;
    if (_pageController.hasClients && (newIndex - (_pageController.page ?? newIndex)).abs() >= 1) {
      _pageController.jumpToPage(newIndex);
    }
  }

  /// Update the displayed page.
  void update() => {if (mounted) setState(() {})};

  /// Wrap a a graph in a column and add a title above of the graph.
  Widget _getGraphWithTitle({required String title, required Widget graph}) {
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
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(
          height: 200,
          child: MapBackground(
            child: PageView(
              controller: _pageController,
              clipBehavior: Clip.hardEdge,
              onPageChanged: (int index) => setState(() {
                // Update tab controller index to update the indicator.
                _tabController.index = index;
                if (index < StatInterval.values.length) {
                  getIt<StatisticService>().setStatInterval(
                    StatInterval.values[index],
                  );
                }
              }),
              children: [
                DailyOverview(today: _viewModel.days.last),
                _getGraphWithTitle(
                  title: 'Diese Woche (Km)',
                  graph: WeekStatsGraph(week: _viewModel.weeks.last),
                ),
                _getGraphWithTitle(
                  title: 'Dieser Monat (Km)',
                  graph: MonthStatsGraph(month: _viewModel.months.last),
                ),
                _getGraphWithTitle(
                  title: '${_viewModel.weeks.length} Wochen Rückblick (Km)',
                  graph: MultipleWeeksStatsGraph(weeks: _viewModel.weeks),
                ),
                FancyRouteStatsForWeek(week: _viewModel.weeks.last),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TabPageSelector(
            controller: _tabController,
            selectedColor: Theme.of(context).colorScheme.primary,
            indicatorSize: 12,
            borderStyle: BorderStyle.none,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
            key: GlobalKey(),
          ),
        ),
      ],
    );
  }
}
