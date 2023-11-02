import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/map_background.dart';
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

  ListOfRideStats get statsOnPage => widget.stats.elementAt(_displayedPageIndex);
  StatType get statType => _statsService.selectedType;
  int? get selectedIndex => statsOnPage.isDayInList(_statsService.selectedDate);
  RideStats? get selectedElement => selectedIndex == null ? null : statsOnPage.list.elementAt(selectedIndex!);

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

  /// Returns a widget displaying the overall or selected value for a given stat type.
  Widget _getStatInfoWidget(StatType type) {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          OnTapAnimation(
            onPressed: () => _statsService.setStatType(type),
            child: Icon(
              getIconForInfoType(type),
              size: 40,
            ),
          ),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: _statsService.selectedType == type ? CI.radkulturRed : Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
          ),
          const SizedBox(height: 8),
          BoldSubHeader(
            text: StringFormatter.getRoundedStrByStatType(
              (selectedElement != null) ? selectedElement!.getStatFromType(type) : statsOnPage.getStatFromType(type),
              type,
            ),
            context: context,
            height: 1,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          ),
          BoldSmall(
            text: StringFormatter.getLabelForStatType(type),
            context: context,
            height: 1,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _statsService.selectDate(null),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 16),
              SubHeader(
                text: StringFormatter.getDescriptionForStatType(_statsService.selectedType),
                context: context,
                height: 1,
              ),
              Expanded(child: Container()),
              if (selectedElement == null) ...[
                BoldContent(
                  text: 'ø',
                  context: context,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                ),
                const SizedBox(width: 2),
                BoldSubHeader(
                  text: StringFormatter.getFormattedStrByStatType(
                    statsOnPage.getAvgFromType(_statsService.selectedType),
                    _statsService.selectedType,
                  ),
                  context: context,
                  height: 1,
                ),
              ],
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(width: 16),
                BoldSmall(
                  text: statsOnPage.getTimeDescription(selectedIndex),
                  context: context,
                ),
              ],
            ),
          ),
          const SmallVSpace(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 224,
              child: MapBackground(
                child: PageView(
                  reverse: true,
                  controller: _pageController,
                  clipBehavior: Clip.hardEdge,
                  children: _getGraphs(),
                ),
              ),
            ),
          ),
          const SmallVSpace(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _getStatInfoWidget(StatType.distance),
                _getStatInfoWidget(StatType.duration),
                _getStatInfoWidget(StatType.speed),
                _getStatInfoWidget(StatType.elevationGain),
                _getStatInfoWidget(StatType.elevationLoss),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
