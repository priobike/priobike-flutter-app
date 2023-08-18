import 'dart:math';

import 'package:collection/collection.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/gamification/statistics/views/utils.dart';
import 'package:priobike/main.dart';

/// This widget displayes detailed statistics for a number of given graphs. It also provides the user with functionality
/// to change the displayed information and time intervals.
class DetailedStatistics extends StatelessWidget {
  final AnimationController headerAnimationController;
  final AnimationController rideListController;
  final PageController pageController;

  /// The graphs, displayed by the widget in a page view to scroll through.
  final List<Widget> graphs;

  /// The viewmodel corresponding to the currently displayed graph.
  final GraphViewModel currentViewModel;

  /// A title for the view.
  final String title;

  /// Simple fade animation for the header and the graphs.
  Animation<double> get _fadeAnimation => CurvedAnimation(
        parent: headerAnimationController,
        curve: const Interval(0, 0.4, curve: Curves.easeIn),
      );

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
    required this.headerAnimationController,
    required this.title,
    required this.rideListController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SmallVSpace(),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(width: 72, height: 64),
                Expanded(
                  child: SubHeader(
                    text: title,
                    context: context,
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),

                  /// By pressing this icon button, the displayed stat intervals can be changed.
                  child: SmallIconButton(
                    icon: Icons.sync_alt,
                    onPressed: () async {
                      headerAnimationController.duration = const Duration(milliseconds: 500);
                      headerAnimationController.reverse();
                      rideListController.duration = const Duration(milliseconds: 500);
                      rideListController.reverse();
                      Future.delayed(const Duration(milliseconds: 500)).then((_) {
                        getIt<StatisticService>().changeStatInterval();
                        headerAnimationController.forward();
                      });
                    },
                    fill: Theme.of(context).colorScheme.background,
                    splash: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ],
            ),
          ),
          const SmallVSpace(),

          /// This widget contains the graphs in a page view and further information for the displayed graph.
          FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: () => currentViewModel.setSelectedIndex(null),
              child: Container(
                color: Theme.of(context).colorScheme.background,
                child: Column(
                  children: [
                    getGraphHeader(context),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
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
                    getGraphFooter(context),
                    getButtonRow(context),
                  ],
                ),
              ),
            ),
          ),

          /// The rides below the graphs are animated into the view after a short delay, to improve performance.
          FutureBuilder<bool>(
            key: GlobalKey(),
            future: Future.delayed(const Duration(milliseconds: 200)).then((value) => true),
            builder: (context, snapshot) {
              if (!(snapshot.data ?? false)) return const SizedBox.shrink();
              rideListController.duration = const Duration(milliseconds: 500);
              rideListController.forward();
              return getRideList(context);
            },
          )
        ],
      ),
    );
  }

  /// Returns simple graph header, which displays values according to the displayed graph or the selected content.
  Widget getGraphHeader(BuildContext context) {
    var isAvg = currentViewModel.rideInfoType == RideInfo.averageSpeed;
    var noSelectedBar = currentViewModel.selectedIndex == null;
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 48, right: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          BoldSubHeader(
            text: (isAvg && noSelectedBar) ? ' ' : currentViewModel.selectedOrOverallValueStr,
            context: context,
          ),
          BoldContent(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            text: 'ø ${currentViewModel.valuesAverage}',
            context: context,
          )
        ],
      ),
    );
  }

  /// Returns a row of buttons which enable the user to change the displayed ride information.
  Widget getButtonRow(var context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 48, right: 48),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          getRideInfoButton(RideInfo.distance, context),
          getRideInfoButton(RideInfo.averageSpeed, context),
          getRideInfoButton(RideInfo.duration, context),
        ],
      ),
    );
  }

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

  /// Returns footer for graph which contains the displayed or selected time interval and buttons to change the page.
  Widget getGraphFooter(var context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        getNavigationButton(Icons.arrow_back_ios, -1),
        Expanded(
          child: SubHeader(
            text: currentViewModel.rangeOrSelectedDateStr,
            context: context,
            textAlign: TextAlign.center,
          ),
        ),
        getNavigationButton(Icons.arrow_forward_ios, 1),
      ],
    );
  }

  /// Return button to navigate between pages.
  Widget getNavigationButton(IconData icon, int direction) {
    return GestureDetector(
      onTap: () {
        /// Animate to next page if button is pressed.
        pageController.animateToPage(
          pageController.page!.toInt() + direction,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeIn,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon),
      ),
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
                    StatUtils.getDateStr(day),
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
                StatUtils.getTimeStr(ride.startTime),
                'Uhr',
                context,
              ),
              getRideInfoValue(
                StatUtils.getRoundedStrByRideType(ride.distanceMetres / 1000, RideInfo.distance),
                'km',
                context,
              ),
              getRideInfoValue(
                StatUtils.getRoundedStrByRideType(ride.durationSeconds / 60, RideInfo.duration),
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
                    StatUtils.getRoundedStrByRideType(ride.averageSpeedKmh, RideInfo.averageSpeed),
                    'ø km/h',
                    context,
                  ),
                  getRideInfoValue(
                    StatUtils.getRoundedStrByRideType(ride.elevationGainMetres, RideInfo.elevationGain),
                    '↑ m',
                    context,
                  ),
                  getRideInfoValue(
                    StatUtils.getRoundedStrByRideType(ride.elevationLossMetres, RideInfo.elevationLoss),
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
