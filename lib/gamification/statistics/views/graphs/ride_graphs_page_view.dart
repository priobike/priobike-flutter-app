import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/gamification/statistics/services/test.dart';
import 'package:priobike/main.dart';

/// This widget contains a number of graphs, displaying ride statistics, in a page view.
class RideGraphsPageView extends StatelessWidget {
  final PageController pageController;

  /// The graphs, displayed by the widget in a page view to scroll through.
  final List<Widget> graphs;

  /// The viewmodel corresponding to the currently displayed graph.
  final StatsForTimeFrameViewModel currentViewModel;

  const RideGraphsPageView({
    Key? key,
    required this.graphs,
    required this.pageController,
    required this.currentViewModel,
  }) : super(key: key);

  /// Returns a simple button for a given ride info type, which changes the selected ride info type when pressed.
  Widget getRideInfoButton(StatType rideInfoType, var context) {
    double value = getIt<StatisticService>().isTypeSelected(rideInfoType) ? 1 : 0;
    return AnimatedButton(
      onPressed: () => getIt<StatisticService>().setStatType(rideInfoType),
      child: Stack(
        children: [
          Center(
            child: SizedBox.fromSize(
              size: const Size.square(48),
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Colors.grey.withOpacity(0.5),
                value: value,
              ),
            ),
          ),
          SizedBox.fromSize(
            size: const Size.square(48),
            child: Center(
              child: Icon(StatisticService.getIconForInfoType(rideInfoType)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var isSpeed = true;
    var barSelected = currentViewModel.selectedIndex != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => currentViewModel.setSelectedIndex(null),
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
                          text: (!isSpeed && barSelected) ? 'GESAMT' : 'DURCHSCHNITT',
                          context: context,
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                        ),
                        BoldSubHeader(
                          text:
                              barSelected ? currentViewModel.selectedOrOverallValueStr : currentViewModel.valuesAverage,
                          context: context,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: (barSelected || isSpeed)
                          ? (barSelected)
                              ? []
                              : []
                          : [
                              BoldSmall(
                                text: 'GESAMT',
                                context: context,
                                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                              ),
                              BoldSubHeader(
                                text: currentViewModel.selectedOrOverallValueStr,
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
                    controller: pageController,
                    clipBehavior: Clip.hardEdge,
                    children: graphs,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [SubHeader(text: currentViewModel.rangeOrSelectedDateStr, context: context)],
              ),
              const SmallVSpace(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    getRideInfoButton(StatType.distance, context),
                    getRideInfoButton(StatType.duration, context),
                    getRideInfoButton(StatType.speed, context),
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
