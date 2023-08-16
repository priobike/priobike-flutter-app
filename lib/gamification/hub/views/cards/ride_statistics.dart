import 'package:flutter/material.dart';
import 'package:priobike/gamification/hub/views/cards/hub_card.dart';
import 'package:priobike/gamification/statistics/views/month_stats.dart';
import 'package:priobike/gamification/statistics/views/multiple_weeks_stats.dart';
import 'package:priobike/gamification/statistics/views/week_stats.dart';

/// A gamification hub card which displays graphs containing statistics of the users' rides.
class RideStatisticsCard extends StatefulWidget {
  const RideStatisticsCard({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return GameHubCard(
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
                WeekStatsView(startDay: DateTime(2023, 8, 14)),
                MonthStatsView(firstDay: DateTime(2023, 8, 1)),
                MultipleWeeksStatsView(
                  firstWeekStartDay: DateTime(2023, 7, 17),
                  lastWeekStartDay: DateTime(2023, 8, 14),
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
          GestureDetector(
            child: Container(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(
                    Icons.expand_more,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                  ),
                  Text(
                    "mehr anzeigen",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
                  ),
                  Icon(
                    Icons.expand_more,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
