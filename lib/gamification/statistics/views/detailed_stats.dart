import 'dart:math';

import 'package:collection/collection.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/main.dart';

/// This widget displayes detailed statistics for a number of given graphs. It also provides the user with functionality
/// to change the displayed information and time intervals.
class DetailedStatistics extends StatelessWidget {
  final AnimationController rideListController;
  final PageController pageController;

  /// The graphs, displayed by the widget in a page view to scroll through.
  final List<Widget> graphs;

  /// The viewmodel corresponding to the currently displayed graph.
  final GraphViewModel currentViewModel;

  /// Animation for the confirmation button. The button slides in from the bottom.
  Animation<Offset> getListAnimation(double start, double end) => Tween<Offset>(
        begin: const Offset(0.0, 5.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: rideListController,
        curve: Interval(min(start, 1.0), min(end, 1.0), curve: Curves.easeIn),
      ));

  const DetailedStatistics({
    Key? key,
    required this.graphs,
    required this.pageController,
    required this.currentViewModel,
    required this.rideListController,
  }) : super(key: key);

  /// Returns a simple button for a given ride info type, which changes the selected ride info type when pressed.
  Widget getRideInfoButton(RideInfo rideInfoType, var context) {
    double value = getIt<StatisticService>().isTypeSelected(rideInfoType) ? 1 : 0;
    return GestureDetector(
      onTap: () => getIt<StatisticService>().setRideInfo(rideInfoType),
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
    var isSpeed = currentViewModel.rideInfoType == RideInfo.averageSpeed;
    var barSelected = currentViewModel.selectedIndex != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// This widget contains the graphs in a page view and further information for the displayed graph.
        GestureDetector(
          onTap: () => currentViewModel.setSelectedIndex(null),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                const SmallVSpace(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
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
                            text: barSelected
                                ? currentViewModel.selectedOrOverallValueStr
                                : currentViewModel.valuesAverage,
                            context: context,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: (barSelected || isSpeed)
                            ? []
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
                      onPageChanged: (_) => rideListController.reset(),
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
                      getRideInfoButton(RideInfo.distance, context),
                      getRideInfoButton(RideInfo.duration, context),
                      getRideInfoButton(RideInfo.averageSpeed, context),
                    ],
                  ),
                ),
                const VSpace(),
              ],
            ),
          ),
        ),

        /// The rides below the graphs are animated into the view after a short delay, to improve performance.
        /*FutureBuilder<bool>(
          key: GlobalKey(),
          future: Future.delayed(const Duration(milliseconds: 200)).then((value) => true),
          builder: (context, snapshot) {
            if (!(snapshot.data ?? false)) return const SizedBox.shrink();
            rideListController.duration = ShortDuration();
            rideListController.forward();
            return getRideList(context);
          },
        )*/
      ],
    );
  }

  /// Returns a list of all rides in the current displayed time interval. The rides are grouped by date.
  Widget getRideList(BuildContext context) {
    var rides = currentViewModel.selectedOrAllRides;

    /// Group rides by day and save in map.
    var groupedRides = rides.groupListsBy((ride) {
      var date = ride.startTime;
      var day = DateTime(date.year, date.month, date.day);
      return day;
    });

    /// Return list of ride groups.
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: groupedRides.entries.mapIndexed((i, entry) {
          if (i < 10) {
            /// The first ten elements in the list appear via slide transition from the bottom.
            return SlideTransition(
              position: getListAnimation(0.2 + (i * 0.2), 0.6 + (i * 0.2)),
              child: getRideListForDay(entry.key, entry.value, context),
            );
          }
          return getRideListForDay(entry.key, entry.value, context);
        }).toList(),
      ),
    );
  }

  /// Returns list of rides for on a given day as a indicator for the day followed by a list of expandable info widget.
  Widget getRideListForDay(DateTime day, List<RideSummary> rides, var context) {
    return Column(
      children: <Widget>[
            Container(
              color: Theme.of(context).colorScheme.background.withOpacity(0.25),
              padding: const EdgeInsets.only(left: 16, bottom: 4, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    StringFormatter.getDateStr(day),
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] +
          rides.map((ride) => getRideInfo(ride, rides.last == ride, context)).toList(),
    );
  }

  /// Returns expandable widget containing information for a single ride.
  Widget getRideInfo(RideSummary ride, bool isLast, var context) {
    return ExpandablePanel(
      theme: ExpandableThemeData(
          headerAlignment: ExpandablePanelHeaderAlignment.center,
          useInkWell: false,
          tapBodyToCollapse: true,
          tapHeaderToExpand: true,
          iconColor: Theme.of(context).colorScheme.onBackground),
      header: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              getRideInfoValue(
                StringFormatter.getTimeStr(ride.startTime),
                'Uhr',
                context,
              ),
              getRideInfoValue(
                StringFormatter.getRoundedStrByRideType(ride.distanceMetres / 1000, RideInfo.distance),
                'km',
                context,
              ),
              getRideInfoValue(
                StringFormatter.getRoundedStrByRideType(ride.durationSeconds / 60, RideInfo.duration),
                'min',
                context,
              ),
            ],
          ),
        ),
      ),
      collapsed: getRideSeperator(isLast, context),
      expanded: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 32),
            child: Material(
              color: Colors.transparent,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  getRideInfoValue(
                    StringFormatter.getRoundedStrByRideType(ride.averageSpeedKmh, RideInfo.averageSpeed),
                    'ø km/h',
                    context,
                  ),
                  getRideInfoValue(
                    StringFormatter.getRoundedStrByRideType(ride.elevationGainMetres, RideInfo.elevationGain),
                    '↑ m',
                    context,
                  ),
                  getRideInfoValue(
                    StringFormatter.getRoundedStrByRideType(ride.elevationLossMetres, RideInfo.elevationLoss),
                    '↓ m',
                    context,
                  ),
                ],
              ),
            ),
          ),
          getRideSeperator(isLast, context),
        ],
      ),
      builder: (_, collapsed, expanded) {
        return Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          child: Expandable(
            collapsed: collapsed,
            expanded: expanded,
            theme: const ExpandableThemeData(crossFadePoint: 0),
          ),
        );
      },
    );
  }

  /// Returns a simple widget displaying a ride info value and a given label.
  Widget getRideInfoValue(String top, String bottom, var context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SubHeader(
          text: top,
          context: context,
        ),
        BoldContent(
          text: bottom,
          context: context,
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
        )
      ],
    );
  }

  /// Simple seperator between ride widgets.
  Widget getRideSeperator(var isLast, var context) {
    return isLast
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(4)),
              child: SizedBox.fromSize(
                size: const Size.fromHeight(2),
              ),
            ),
          );
  }
}
