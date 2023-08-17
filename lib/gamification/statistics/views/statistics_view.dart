import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/statistics/graphs/week/detailed_week_graph.dart';

class StatisticsView extends StatefulWidget {
  const StatisticsView({Key? key}) : super(key: key);

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> with SingleTickerProviderStateMixin {
  /// Controller which controls the animation when opening this view.
  late AnimationController _animationController;

  Animation<double> get _fadeAnimation => CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.4, curve: Curves.easeIn),
      );

  @override
  void initState() {
    // Init animation controller and start the animation after a short delay, to let the view load first.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
    super.initState();
  }

  @override
  void dispose() {
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
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const SmallVSpace(),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  AppBackButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const HSpace(),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SubHeader(
                        text: "Wochenübersicht",
                        context: context,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const HSpace(),
                  const SizedBox(width: 56, height: 0),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SmallVSpace(),
                      DetailedWeekGraph(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*
  List<Widget> getMonthStatistics(int numOfMonths) {
    List<Widget> stats = [];
    var month = DateTime.now().month;
    var year = DateTime.now().year;
    for (int i = 0; i < numOfMonths; i++) {
      stats.add(MonthStatsGraph(
        year: year,
        month: month,
        tabHandler: () {},
        onChanged: (List<double> values, int? selected) {},
      ));
      if (month == 1) {
        month = 12;
        year -= 1;
      } else {
        month -= 1;
      }
    }
    return stats.reversed.toList();
  }

  List<Widget> getMultipleWeekStatistics(int numOfIntervals) {
    List<Widget> stats = [];
    var today = DateTime.now();
    var weekStart = today.subtract(Duration(days: today.weekday - 1));
    weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
    for (int i = 0; i < numOfIntervals; i++) {
      stats.add(MultipleWeeksStatsGraph(
        lastWeekStartDay: weekStart,
        numOfWeeks: 5,
        tabHandler: () {},
        onChanged: (List<double> values, List<DateTime> weekStarts, int? selected) {},
      ));
      weekStart = weekStart.subtract(Duration(days: 7 * numOfIntervals));
    }
    return stats.reversed.toList();
  }*/
}
