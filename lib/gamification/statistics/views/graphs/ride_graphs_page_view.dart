import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/gamification/statistics/models/stat_type.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/main.dart';

/// This widget contains a number of graphs, displaying ride statistics, in a page view.
class RideGraphsPageView extends StatefulWidget {
  /// The graphs, displayed by the widget in a page view to scroll through.
  final List<Widget> graphs;

  /// The data of the currently displayed page.
  final List<ListOfRideStats> displayedStats;

  const RideGraphsPageView({
    Key? key,
    required this.graphs,
    required this.displayedStats,
  }) : super(key: key);
  @override
  State<RideGraphsPageView> createState() => _RideGraphsPageViewState();
}

class _RideGraphsPageViewState extends State<RideGraphsPageView> {
  late PageController pageController;

  late StatisticService statsService;

  int displayedPageIndex = 0;

  List<ListOfRideStats<WeekStats>> displayedStats = [];

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  void initState() {
    statsService = getIt<StatisticService>();
    statsService.addListener(update);
    pageController = PageController(initialPage: displayedStats.length - 1);
    pageController.addListener(() {
      setState(() => displayedPageIndex = pageController.page!.round());
    });
    super.initState();
  }

  @override
  void dispose() {
    statsService.removeListener(update);
    pageController.dispose();
    super.dispose();
  }

  /// Returns a simple button for a given ride info type, which changes the selected ride info type when pressed.
  Widget getRideInfoButton(StatType type) {
    return AnimatedButton(
      onPressed: () => statsService.setStatType(type),
      child: Stack(
        children: [
          Center(
            child: SizedBox.fromSize(
              size: const Size.square(48),
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Colors.grey.withOpacity(0.5),
                value: statsService.isTypeSelected(type) ? 1 : 0,
              ),
            ),
          ),
          SizedBox.fromSize(
            size: const Size.square(48),
            child: Center(
              child: Icon(StatisticService.getIconForInfoType(type)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var statsOnPage = widget.displayedStats.elementAt(displayedPageIndex);
    var statType = statsService.rideInfo;
    var selectedIndex = statsOnPage.isDayInList(statsService.selectedDate);
    var selectedElement = selectedIndex == null ? null : statsOnPage.list.elementAt(selectedIndex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => statsService.setSelectedDate(null),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BoldSmall(
                          text: (statType != StatType.speed && selectedIndex != null) ? 'GESAMT' : 'DURCHSCHNITT',
                          context: context,
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                        ),
                        BoldSubHeader(
                          text: StringFormatter.getFormattedStrByRideType(
                              (selectedElement != null)
                                  ? selectedElement.getStatFromType(statType)
                                  : statsOnPage.getAvgFromType(statType),
                              statType),
                          context: context,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: (selectedElement != null || statType == StatType.speed)
                          ? (selectedElement != null)
                              ? []
                              : []
                          : [
                              BoldSmall(
                                text: 'GESAMT',
                                context: context,
                                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                              ),
                              BoldSubHeader(
                                text: StringFormatter.getFormattedStrByRideType(
                                    (selectedElement != null)
                                        ? selectedElement.getStatFromType(statType)
                                        : statsOnPage.getStatFromType(statType),
                                    statType),
                                context: context,
                              ),
                            ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 224,
                  child: PageView(
                    reverse: true,
                    controller: pageController,
                    clipBehavior: Clip.hardEdge,
                    children: widget.graphs,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SubHeader(
                    text: statsOnPage.getTimeDescription(selectedIndex),
                    context: context,
                  ),
                ],
              ),
              const SmallVSpace(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    getRideInfoButton(StatType.distance),
                    getRideInfoButton(StatType.duration),
                    getRideInfoButton(StatType.speed),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
