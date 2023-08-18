import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
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
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late StatisticService statService;

  void update() => setState(() {});

  @override
  void initState() {
    statService = getIt<StatisticService>();
    statService.addListener(update);
    // Init the animation controllers and start the header animation.
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    Future.delayed(const Duration(milliseconds: 0)).then((value) => _headerAnimationController.forward());
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    super.initState();
  }

  @override
  void dispose() {
    statService.removeListener(update);
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Stack(
            children: [
              /// Display ride statistics according to current selected interval.
              if (statService.statInterval == StatInterval.weeks)
                DetailedWeekStats(
                  headerAnimationController: _headerAnimationController,
                  rideListController: _listAnimationController,
                ),
              if (statService.statInterval == StatInterval.months)
                DetailedMonthStats(
                  headerAnimationController: _headerAnimationController,
                  rideListController: _listAnimationController,
                ),
              if (statService.statInterval == StatInterval.multipleWeeks)
                DetailedMultipleWeekStats(
                  headerAnimationController: _headerAnimationController,
                  rideListController: _listAnimationController,
                ),

              /// Back button on top of the displayed statistics.
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    AppBackButton(
                      onPressed: () async {
                        _headerAnimationController.duration = const Duration(milliseconds: 500);
                        _headerAnimationController.reverse();
                        _listAnimationController.duration = const Duration(milliseconds: 500);
                        _listAnimationController.reverse();
                        if (!mounted) return;
                        Future.delayed(const Duration(milliseconds: 500)).then((_) => Navigator.of(context).pop());
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
