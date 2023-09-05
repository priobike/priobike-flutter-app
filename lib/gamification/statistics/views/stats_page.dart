import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/custom_page.dart';
import 'package:priobike/gamification/statistics/views/graphs/month/month_stats.dart';
import 'package:priobike/gamification/statistics/views/graphs/multiple_weeks/multiple_weeks_stats.dart';
import 'package:priobike/gamification/statistics/views/graphs/week/week_stats.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/gamification/statistics/views/overall_stats.dart';
import 'package:priobike/main.dart';

/// This view provides the user with detailed statistics about their ride history.
class StatisticsView extends StatefulWidget {
  const StatisticsView({Key? key}) : super(key: key);

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  late StatisticService statService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  void initState() {
    statService = getIt<StatisticService>();
    statService.addListener(update);
    _listAnimationController = AnimationController(vsync: this, duration: ShortDuration());
    super.initState();
  }

  @override
  void dispose() {
    statService.removeListener(update);
    _listAnimationController.dispose();
    super.dispose();
  }

  /// Get widget header title from stat interval.
  String getTitleFromStatInterval(StatInterval interval) {
    if (interval == StatInterval.weeks) return 'Wochenübersicht';
    if (interval == StatInterval.multipleWeeks) return 'Mehrere Wochen';
    if (interval == StatInterval.months) return 'Monatsübersicht';
    return '';
  }

  /// Get ride statistic view according to stat interval.
  Widget getStatsViewFromInterval(StatInterval interval) {
    if (statService.statInterval == StatInterval.weeks) {
      return DetailedWeekStats(rideListController: _listAnimationController);
    }
    if (statService.statInterval == StatInterval.months) {
      return DetailedMonthStats(rideListController: _listAnimationController);
    }
    if (statService.statInterval == StatInterval.multipleWeeks) {
      return DetailedMultipleWeekStats(rideListController: _listAnimationController);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPage(
      title: 'Deine Fahrtstatistiken',
      backButtonCallback: () async {
        _listAnimationController.duration = ShortDuration();
        _listAnimationController.reverse();
        if (!mounted) return;
        Future.delayed(ShortDuration()).then((_) => Navigator.of(context).pop());
      },
      featureButtonIcon: Icons.sync_alt,
      featureButtonCallback: () async {
        _listAnimationController.duration = ShortDuration();
        _listAnimationController.reverse();
        Future.delayed(ShortDuration()).then((_) {
          getIt<StatisticService>().changeStatInterval();
        });
      },
      content: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.background,
            child: const OverallStatistics(),
          ),
          getStatsViewFromInterval(statService.statInterval),
        ],
      ),
    );
  }
}
