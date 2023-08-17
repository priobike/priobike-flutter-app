import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/number_symbols_data.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/statistics/views/month_stats.dart';
import 'package:priobike/gamification/statistics/views/multiple_weeks_stats.dart';
import 'package:priobike/gamification/statistics/views/week_stats.dart';

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
                        text: "Fahrt-Statistiken",
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
                    children: [
                      const SmallVSpace(),
                      StatisticsHistoryView(pages: getWeekStatistics(10)),
                      const SmallVSpace(),
                      StatisticsHistoryView(pages: getMonthStatistics(6)),
                      const SmallVSpace(),
                      StatisticsHistoryView(pages: getMultipleWeekStatistics(5)),
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

  List<Widget> getWeekStatistics(int numOfWeeks) {
    List<Widget> stats = [];
    var today = DateTime.now();
    var weekStart = today.subtract(Duration(days: today.weekday - 1));
    weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
    for (int i = 0; i < numOfWeeks; i++) {
      var tmpWeekStart = weekStart.subtract(Duration(days: 7 * i));
      stats.add(
        WeekStatsView(startDay: tmpWeekStart, tabHandler: () {}),
      );
    }
    return stats.reversed.toList();
  }

  List<Widget> getMonthStatistics(int numOfMonths) {
    List<Widget> stats = [];
    var month = DateTime.now().month;
    var year = DateTime.now().year;
    for (int i = 0; i < numOfMonths; i++) {
      stats.add(MonthStatsView(year: year, month: month, tabHandler: () {}));
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
      stats.add(MultipleWeeksStatsView(lastWeekStartDay: weekStart, numOfWeeks: 5, tabHandler: () {}));
      weekStart = weekStart.subtract(Duration(days: 7 * numOfIntervals));
    }
    return stats.reversed.toList();
  }
}

class StatisticsHistoryView extends StatelessWidget {
  final List<Widget> pages;

  const StatisticsHistoryView({Key? key, required this.pages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Controller for the page view displaying the different statistics.
    final PageController pageController = PageController(initialPage: pages.length - 1);
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 224,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 20, left: 8),
                child: GestureDetector(
                  onTap: () {
                    pageController.animateToPage(
                      pageController.page!.toInt() - 1,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeIn,
                    );
                  },
                  child: const Icon(Icons.arrow_back_ios),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: pageController,
                clipBehavior: Clip.hardEdge,
                children: pages,
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 20, left: 8),
                child: GestureDetector(
                  onTap: () {
                    pageController.animateToPage(
                      pageController.page!.toInt() + 1,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeIn,
                    );
                  },
                  child: const Icon(Icons.arrow_forward_ios),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
