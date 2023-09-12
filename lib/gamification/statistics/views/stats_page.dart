import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/gamification/statistics/models/stat_type.dart';
import 'package:priobike/gamification/statistics/services/stats_view_model.dart';
import 'package:priobike/gamification/statistics/views/graphs/ride_graphs_page_view.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/gamification/statistics/views/route_goals_history.dart';
import 'package:priobike/main.dart';

/// This view provides the user with detailed statistics about their ride history.
class StatisticsView extends StatefulWidget {
  const StatisticsView({Key? key}) : super(key: key);

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> with TickerProviderStateMixin {
  /// The view model, which hold all the stats displayed by the view.
  late StatisticsViewModel _viewModel;

  /// The interval in which rides shall be displayed.
  late StatInterval _statInterval;

  @override
  void initState() {
    _statInterval = getIt<StatisticService>().statInterval;
    _initViewModel();
    super.initState();
  }

  @override
  void dispose() {
    _viewModel.removeListener(update);
    _viewModel.dispose();
    super.dispose();
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  /// Initialize view model to hold data for the last year.
  void _initViewModel() {
    var today = DateTime.now();
    today = DateTime(today.year, today.month, today.day);
    var todayLastYear = DateTime(today.year - 1, today.month, today.day);
    _viewModel = StatisticsViewModel(startDate: todayLastYear, endDate: today);
    _viewModel.addListener(update);
  }

  /// Get ride statistic view according to stat interval.
  Widget _getStatsViewFromInterval(StatInterval interval) {
    // If the stat interval ist weeks, return a page view for all weeks in the view model.
    if (_statInterval == StatInterval.weeks && _viewModel.weeks.isNotEmpty) {
      return RideGraphsPageView(
        key: const ValueKey('weeks'),
        stats: _viewModel.weeks.reversed.toList(),
      );
    }
    // If the stat interval ist months, return a page view for all months in the view model.
    else if (_statInterval == StatInterval.months && _viewModel.months.isNotEmpty) {
      return RideGraphsPageView(
        key: const ValueKey('months'),
        stats: _viewModel.months.reversed.toList(),
      );
    }
    // If the stat interval ist multiple weeks, built groups of 5 weeks from the weeks
    // in the view model and return a page view for the week-groups.
    else if (_statInterval == StatInterval.multipleWeeks) {
      int weeksPerGraph = 5;
      List<ListOfRideStats<WeekStats>> displayedStats = [];
      var allWeeks = List.from(_viewModel.weeks);
      while (allWeeks.length >= weeksPerGraph) {
        List<WeekStats> weeks = [];
        for (int i = 0; i < weeksPerGraph; i++) {
          weeks.insert(0, allWeeks.removeLast());
        }
        displayedStats.add(ListOfRideStats<WeekStats>(weeks));
      }
      if (displayedStats.isNotEmpty) {
        return RideGraphsPageView(
          key: const ValueKey('multiWeeks'),
          stats: displayedStats,
        );
      }
    }
    return const SizedBox.shrink();
  }

  /// Reset the selected date and type, to not make the stat card on the home screen confusing.
  void _resetGraphs() {
    getIt<StatisticService>().selectDate(null);
    getIt<StatisticService>().setStatType(StatType.distance);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: WillPopScope(
        onWillPop: () async {
          _resetGraphs();
          return true;
        },
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
                        onPressed: () {
                          _resetGraphs();
                          Navigator.pop(context);
                        },
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
                  child: _getStatsViewFromInterval(_statInterval),
                ),
                Expanded(child: Container()),
                RouteGoalsHistory(viewModel: _viewModel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Button to change the displayed stat interval.
class IntervalSelectionButton extends StatefulWidget {
  /// The stat interval corresponding to the button.
  final StatInterval interval;

  /// If the interval is currently selected.
  final bool selected;

  /// Callback for when the button is tapped.
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
  bool _tapDown = false;

  /// Get widget header title from stat interval.
  String _getTitleFromStatInterval(StatInterval interval) {
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
        onTapDown: (_) => setState(() => _tapDown = true),
        onTapUp: (_) => setState(() => _tapDown = false),
        onTapCancel: () => setState(() => _tapDown = false),
        onTap: () {
          widget.onTap();
          setState(() {});
          getIt<StatisticService>().setStatInterval(widget.interval);
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Content(
                text: _getTitleFromStatInterval(widget.interval),
                context: context,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(_tapDown ? 0.1 : 1),
              ),
              const SmallVSpace(),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                height: 4,
                decoration: BoxDecoration(
                  color: widget.selected
                      ? CI.blue
                      : Theme.of(context).colorScheme.onBackground.withOpacity(_tapDown ? 0.01 : 0.05),
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
