import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/custom_page.dart';
import 'package:priobike/gamification/statistics/views/graphs/month/month_stats.dart';
import 'package:priobike/gamification/statistics/views/graphs/multiple_weeks/multiple_weeks_stats.dart';
import 'package:priobike/gamification/statistics/views/graphs/week/week_stats.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/main.dart';

/// This view provides the user with detailed statistics about their ride history.
class StatisticsView extends StatefulWidget {
  const StatisticsView({Key? key}) : super(key: key);

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  late StatisticService _statService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  void initState() {
    _statService = getIt<StatisticService>();
    _statService.addListener(update);
    _listAnimationController = AnimationController(vsync: this, duration: ShortDuration());
    super.initState();
  }

  @override
  void dispose() {
    _statService.removeListener(update);
    _listAnimationController.dispose();
    super.dispose();
  }

  /// Get widget header title from stat interval.
  String getTitleFromStatInterval(StatInterval interval) {
    if (interval == StatInterval.weeks) return 'Woche';
    if (interval == StatInterval.multipleWeeks) return '5 Wochen';
    if (interval == StatInterval.months) return 'Monat';
    return '';
  }

  /// Get ride statistic view according to stat interval.
  Widget getStatsViewFromInterval(StatInterval interval) {
    if (_statService.statInterval == StatInterval.weeks) {
      return DetailedWeekStats(rideListController: _listAnimationController);
    }
    if (_statService.statInterval == StatInterval.months) {
      return DetailedMonthStats(rideListController: _listAnimationController);
    }
    if (_statService.statInterval == StatInterval.multipleWeeks) {
      return DetailedMultipleWeekStats(rideListController: _listAnimationController);
    }
    return const SizedBox.shrink();
  }

  Widget getIntervalButton(StatInterval interval) {
    var selected = _statService.statInterval == interval;
    return Expanded(
      child: Material(
        child: InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () => _statService.setStatInterval(interval),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                Content(text: getTitleFromStatInterval(interval), context: context),
                const SmallVSpace(),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  height: 4,
                  decoration: BoxDecoration(
                    color: selected ? CI.blue : Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget getButtonRow() {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: StatInterval.values.map((interval) => IntervalSelectionButton(interval: interval)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPage(
      title: 'Fahrtstatistiken',
      backButtonCallback: () async {
        _listAnimationController.duration = ShortDuration();
        _listAnimationController.reverse();
        if (!mounted) return;
        Future.delayed(ShortDuration()).then((_) => Navigator.of(context).pop());
      },
      content: Column(
        children: [
          getButtonRow(),
          getStatsViewFromInterval(_statService.statInterval),
        ],
      ),
    );
  }
}

class IntervalSelectionButton extends StatefulWidget {
  final StatInterval interval;

  const IntervalSelectionButton({Key? key, required this.interval}) : super(key: key);

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
    var statService = getIt<StatisticService>();
    var selected = statService.statInterval == widget.interval;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => setState(() => tapDown = true),
        onTapUp: (_) => setState(() => tapDown = false),
        onTapCancel: () => setState(() => tapDown = false),
        onTap: () => statService.setStatInterval(widget.interval),
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
                  color: selected
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
