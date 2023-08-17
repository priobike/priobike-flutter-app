import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:priobike/gamification/hub/views/cards/hub_card.dart';
import 'package:priobike/gamification/statistics/views/month_stats.dart';
import 'package:priobike/gamification/statistics/views/multiple_weeks_stats.dart';
import 'package:priobike/gamification/statistics/views/statistics_view.dart';
import 'package:priobike/gamification/statistics/views/week_stats.dart';

/// A gamification hub card which displays graphs containing statistics of the users' rides.
class RideStatisticsCard extends StatefulWidget {
  final Function(Widget view) openView;

  const RideStatisticsCard({Key? key, required this.openView}) : super(key: key);

  @override
  State<RideStatisticsCard> createState() => _RideStatisticsCardState();
}

class _RideStatisticsCardState extends State<RideStatisticsCard> with SingleTickerProviderStateMixin {
  // Controller for the page view displaying the different statistics.
  final PageController pageController = PageController();

  /// Controller which connects the tab indicator to the page view.
  late final TabController tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    tabController.dispose();
    pageController.dispose();
    super.dispose();
  }

  Future<void> onTap() async {
    widget.openView(const StatisticsView());
  }

  @override
  Widget build(BuildContext context) {
    return GameHubCard(
      onTap: onTap,
      content: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 224,
            child: PageView(
              controller: pageController,
              clipBehavior: Clip.hardEdge,
              onPageChanged: (int index) => setState(() {
                // Update tab controller index to update the indicator.
                tabController.index = index;
              }),
              children: [
                WeekStatsView(
                  startDay: DateTime(2023, 8, 14),
                  tabHandler: onTap,
                  headerTitle: 'Diese Woche',
                ),
                MonthStatsView(
                  year: 2023,
                  month: 8,
                  tabHandler: onTap,
                  headerTitle: 'Dieser Monat',
                ),
                MultipleWeeksStatsView(
                  lastWeekStartDay: DateTime(2023, 8, 14),
                  numOfWeeks: 5,
                  tabHandler: onTap,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TabPageSelector(
              controller: tabController,
              selectedColor: Theme.of(context).colorScheme.primary,
              indicatorSize: 6,
              borderStyle: BorderStyle.none,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
              key: GlobalKey(),
            ),
          ),
        ],
      ),
    );
  }
}
