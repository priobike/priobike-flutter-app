import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/hub/views/cards/hub_card.dart';
import 'package:priobike/gamification/statistics/graphs/month/compact_month_graph.dart';
import 'package:priobike/gamification/statistics/graphs/month/month_graph.dart';
import 'package:priobike/gamification/statistics/graphs/multiple_weeks/compact_multiple_weeks_graph.dart';
import 'package:priobike/gamification/statistics/graphs/week/compact_week_graph.dart';
import 'package:priobike/gamification/statistics/graphs/week/week_graph.dart';
import 'package:priobike/gamification/statistics/graphs/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/graphs/multiple_weeks/multiple_weeks_graph.dart';
import 'package:priobike/gamification/statistics/views/statistics_view.dart';
import 'package:priobike/gamification/statistics/views/utils.dart';

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
                CompactWeekGraph(tabHandler: onTap),
                CompactMonthStatsGraph(tabHandler: onTap),
                CompactMultipleWeeksGraph(tabHandler: onTap),
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
