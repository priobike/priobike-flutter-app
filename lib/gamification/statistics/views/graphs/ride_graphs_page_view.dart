import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/on_tap_animation.dart';
import 'package:priobike/gamification/statistics/models/ride_stats.dart';
import 'package:priobike/gamification/statistics/models/stat_type.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/gamification/statistics/views/graphs/month_graph.dart';
import 'package:priobike/gamification/statistics/views/graphs/multiple_weeks_graph.dart';
import 'package:priobike/gamification/statistics/views/graphs/week_graph.dart';
import 'package:priobike/main.dart';

/// This widget displays a list of ride stats in an interactive page view containing the corresponding graphs.
class RideGraphsPageView extends StatefulWidget {
  /// The data of the currently displayed page.
  final List<ListOfRideStats> stats;

  const RideGraphsPageView({
    Key? key,
    required this.stats,
  }) : super(key: key);
  @override
  State<RideGraphsPageView> createState() => _RideGraphsPageViewState();
}

class _RideGraphsPageViewState extends State<RideGraphsPageView> {
  /// Controller to controll the page view.
  final PageController _pageController = PageController(initialPage: 0);

  /// Stat service to change selected date and stat type.
  late StatisticService _statsService;

  /// Index of the page currently displayed by the page view.
  int _displayedPageIndex = 0;

  @override
  void initState() {
    _statsService = getIt<StatisticService>();
    _statsService.addListener(update);
    _pageController.addListener(() => setState(() => _displayedPageIndex = _pageController.page!.round()));
    super.initState();
  }

  @override
  void dispose() {
    _statsService.removeListener(update);
    _pageController.dispose();
    super.dispose();
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  /// Get list of graphs according the stats given to the widget.
  List<Widget> _getGraphs() {
    return widget.stats.map<Widget>((element) {
      if (element is WeekStats) return WeekStatsGraph(week: element);
      if (element is MonthStats) return MonthStatsGraph(month: element);
      if (element is ListOfRideStats<WeekStats>) return MultipleWeeksStatsGraph(weeks: element.list);
      return const SizedBox.shrink();
    }).toList();
  }

  /// Returns a simple button for a given ride info type, which changes the selected ride info type when pressed.
  Widget _getRideInfoButton(StatType type) {
    return OnTapAnimation(
      onPressed: () => _statsService.setStatType(type),
      child: Stack(
        children: [
          Center(
            child: SizedBox.fromSize(
              size: const Size.square(48),
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Colors.grey.withOpacity(0.5),
                value: _statsService.isTypeSelected(type) ? 1 : 0,
              ),
            ),
          ),
          SizedBox.fromSize(
            size: const Size.square(48),
            child: Center(
              child: Icon(getIconForInfoType(type)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var statsOnPage = widget.stats.elementAt(_displayedPageIndex);
    var statType = _statsService.selectedType;
    var selectedIndex = statsOnPage.isDayInList(_statsService.selectedDate);
    var selectedElement = selectedIndex == null ? null : statsOnPage.list.elementAt(selectedIndex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _statsService.selectDate(null),
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
                    controller: _pageController,
                    clipBehavior: Clip.hardEdge,
                    children: _getGraphs(),
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
                    _getRideInfoButton(StatType.distance),
                    _getRideInfoButton(StatType.duration),
                    _getRideInfoButton(StatType.speed),
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
