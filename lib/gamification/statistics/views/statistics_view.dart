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

  @override
  void initState() {
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
              DetailedWeekGraph(animationController: _animationController),
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
