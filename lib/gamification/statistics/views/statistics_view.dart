import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/gamification/statistics/graphs/month/month_stats.dart';
import 'package:priobike/gamification/statistics/graphs/multiple_weeks/multiple_weeks_stats.dart';
import 'package:priobike/gamification/statistics/graphs/week/week_stats.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/main.dart';

class StatisticsView extends StatefulWidget {
  const StatisticsView({Key? key}) : super(key: key);

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> with SingleTickerProviderStateMixin {
  /// Controller which controls the animation when opening this view.
  late AnimationController _animationController;

  late StatisticService statService;

  void update() => setState(() {});

  @override
  void initState() {
    statService = getIt<StatisticService>();
    statService.addListener(update);
    // Init animation controller and start the animation after a short delay, to let the view load first.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    Future.delayed(const Duration(milliseconds: 0)).then((value) => _animationController.forward());
    super.initState();
  }

  @override
  void dispose() {
    statService.removeListener(update);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Stack(
            children: [
              if (statService.statsType == RideStatsType.weeks)
                DetailedWeekStats(animationController: _animationController),
              if (statService.statsType == RideStatsType.months)
                DetailedMonthStats(animationController: _animationController),
              if (statService.statsType == RideStatsType.multipleWeeks)
                DetailedMultipleWeekStats(animationController: _animationController),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    AppBackButton(
                      onPressed: () async {
                        _animationController.duration = const Duration(milliseconds: 500);
                        await _animationController.reverse();
                        if (!mounted) return;
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
