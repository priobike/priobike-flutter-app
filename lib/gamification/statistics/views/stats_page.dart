import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/gamification/statistics/services/stats_view_model.dart';
import 'package:priobike/gamification/statistics/views/graphs/month_graph.dart';
import 'package:priobike/gamification/statistics/views/graphs/multiple_weeks_graph.dart';
import 'package:priobike/gamification/statistics/views/graphs/ride_graphs_page_view.dart';
import 'package:priobike/gamification/statistics/views/graphs/week_graph.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/gamification/statistics/views/route_goals_history.dart';

/// This view provides the user with detailed statistics about their ride history.
class StatisticsView extends StatefulWidget {
  const StatisticsView({Key? key}) : super(key: key);

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> with TickerProviderStateMixin {
  late StatisticsViewModel viewModel;

  /// The interval in which rides shall be displayed.
  StatInterval _statInterval = StatInterval.weeks;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  void initState() {
    initViewModel();
    super.initState();
  }

  @override
  void dispose() {
    viewModel.removeListener(update);
    viewModel.dispose();
    super.dispose();
  }

  /// Initialize view model to hold data for the last year.
  void initViewModel() {
    var today = DateTime.now();
    today = DateTime(today.year, today.month, today.day);
    var todayLastYear = DateTime(today.year - 1, today.month, today.day);
    viewModel = StatisticsViewModel(startDate: todayLastYear, endDate: today);
    viewModel.addListener(update);
  }

  /// Get ride statistic view according to stat interval.
  Widget getStatsViewFromInterval(StatInterval interval) {
    if (_statInterval == StatInterval.weeks && viewModel.weeks.isNotEmpty) {
      var reverseWeeks = viewModel.weeks.reversed.toList();
      return RideGraphsPageView(
        graphs: reverseWeeks.map((week) => WeekStatsGraph(week: week)).toList(),
        displayedStats: reverseWeeks,
      );
    } else if (_statInterval == StatInterval.months && viewModel.months.isNotEmpty) {
      var reversedMonths = viewModel.months.reversed.toList();
      return RideGraphsPageView(
        key: const ValueKey('month'),
        graphs: reversedMonths.map((month) => MonthStatsGraph(month: month)).toList(),
        displayedStats: reversedMonths,
      );
    } else if (_statInterval == StatInterval.multipleWeeks) {
      int weeksPerGraph = 5;
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
        key: const ValueKey('multiWeeks'),
        graphs: displayedStats
            .map(
              (element) => MultipleWeeksStatsGraph(weeks: element.list),
            )
            .toList(),
        displayedStats: displayedStats,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: Column(
            children: [
              const SmallVSpace(),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 0.5,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: AppBackButton(
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const HSpace(),
                  SubHeader(
                    text: 'Statistiken',
                    context: context,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SmallVSpace(),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: StatInterval.values
                    .map((interval) => IntervalSelectionButton(
                          interval: interval,
                          selected: _statInterval == interval,
                          onTap: () => setState(() => _statInterval = interval),
                        ))
                    .toList(),
              ),
              Expanded(child: Container()),
              AnimatedSwitcher(
                duration: ShortDuration(),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: getStatsViewFromInterval(_statInterval),
              ),
              Expanded(child: Container()),
              RouteGoalsHistory(viewModel: viewModel),
            ],
          ),
        ),
      ),
    );
  }
}

class IntervalSelectionButton extends StatefulWidget {
  final StatInterval interval;

  final bool selected;

  final Function() onTap;

  const IntervalSelectionButton({
    Key? key,
    required this.interval,
    required this.onTap,
    required this.selected,
  }) : super(key: key);

  @override
  State<IntervalSelectionButton> createState() => _IntervalSelectionButtonState();
}

class _IntervalSelectionButtonState extends State<IntervalSelectionButton> {
  bool tapDown = false;

  /// Get widget header title from stat interval.
  String getTitleFromStatInterval(StatInterval interval) {
    if (interval == StatInterval.weeks) return 'Woche';
    if (interval == StatInterval.multipleWeeks) return '5 Wochen';
    if (interval == StatInterval.months) return 'Monat';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => setState(() => tapDown = true),
        onTapUp: (_) => setState(() => tapDown = false),
        onTapCancel: () => setState(() => tapDown = false),
        onTap: () {
          widget.onTap();
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Content(
                text: getTitleFromStatInterval(widget.interval),
                context: context,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(tapDown ? 0.1 : 1),
              ),
              const SmallVSpace(),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                height: 4,
                decoration: BoxDecoration(
                  color: widget.selected
                      ? CI.blue
                      : Theme.of(context).colorScheme.onBackground.withOpacity(tapDown ? 0.01 : 0.05),
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
