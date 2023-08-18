import 'dart:math';

import 'package:collection/collection.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/statistics/graphs/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/gamification/statistics/views/utils.dart';
import 'package:priobike/main.dart';

class DetailedGraph extends StatelessWidget {
  final AnimationController animationController;

  final PageController pageController;

  final List<Widget> graphs;

  final GraphViewModel currentViewModel;

  Animation<double> get _fadeAnimation => CurvedAnimation(
        parent: animationController,
        curve: const Interval(0, 0.4, curve: Curves.easeIn),
      );

  /// Animation for the confirmation button. The button slides in from the bottom.
  Animation<Offset> getListAnimation(double start, double end) => Tween<Offset>(
        begin: const Offset(0.0, 5.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Interval(min(start, 1.0), min(end, 1.0), curve: Curves.easeIn),
      ));

  const DetailedGraph({
    Key? key,
    required this.graphs,
    required this.pageController,
    required this.currentViewModel,
    required this.animationController,
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
                    text: "Wochenübersicht",
                    context: context,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 64, height: 64),
              ],
            ),
          ),
          const SmallVSpace(),
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
          getRideList(context),
        ],
      ),
    );
  }

  Widget getGraphHeader(BuildContext context) {
    var isAvg = currentViewModel.rideInfoType == RideInfoType.averageSpeed;
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

  Widget getButtonRow(var context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 48, right: 48),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          getValueInfo(RideInfoType.distance, context),
          getValueInfo(RideInfoType.averageSpeed, context),
          getValueInfo(RideInfoType.duration, context),
        ],
      ),
    );
  }

  Widget getValueInfo(RideInfoType rideInfoType, var context) {
    double value = getIt<StatisticService>().isTypeSelected(rideInfoType) ? 1 : 0;
    return GestureDetector(
      onTap: () => getIt<StatisticService>().setRideInfoType(rideInfoType),
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

  Widget getGraphFooter(var context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            pageController.animateToPage(
              pageController.page!.toInt() - 1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeIn,
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.arrow_back_ios),
          ),
        ),
        Expanded(
          child: SubHeader(
            text: currentViewModel.rangeOrSelectedDateStr,
            context: context,
            textAlign: TextAlign.center,
          ),
        ),
        GestureDetector(
          onTap: () {
            pageController.animateToPage(
              pageController.page!.toInt() + 1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeIn,
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.arrow_forward_ios),
          ),
        ),
      ],
    );
  }

  Widget getRideList(BuildContext context) {
    var rides = currentViewModel.allRides;
    var groupedRides = rides.groupListsBy((ride) {
      var date = ride.startTime;
      var day = DateTime(date.year, date.month, date.day);
      return day;
    });
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: groupedRides.entries
            .mapIndexed(
              (i, entry) => SlideTransition(
                position: getListAnimation(0.2 + (i * 0.2), 0.6 + (i * 0.2)),
                child: getRideListForDay(entry.key, entry.value, context),
              ),
            )
            .toList(),
      ),
    );
  }

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
          rides.map((ride) => getExpandable(ride, rides.last == ride, context)).toList(),
    );
  }

  Widget getExpandable(RideSummary ride, bool isLast, var context) {
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
              getRideValueInfoWidget(
                StatUtils.getTimeStr(ride.startTime),
                'Uhr',
                context,
              ),
              getRideValueInfoWidget(
                StatUtils.getRoundedStrByRideType(ride.distanceMetres / 1000, RideInfoType.distance),
                'km',
                context,
              ),
              getRideValueInfoWidget(
                StatUtils.getRoundedStrByRideType(ride.durationSeconds / 60, RideInfoType.duration),
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
                  getRideValueInfoWidget(
                    StatUtils.getRoundedStrByRideType(ride.averageSpeedKmh, RideInfoType.averageSpeed),
                    'ø km/h',
                    context,
                  ),
                  getRideValueInfoWidget(
                    StatUtils.getRoundedStrByRideType(ride.elevationGainMetres, RideInfoType.elevationGain),
                    '↑ m',
                    context,
                  ),
                  getRideValueInfoWidget(
                    StatUtils.getRoundedStrByRideType(ride.elevationLossMetres, RideInfoType.elevationLoss),
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

  Widget getRideValueInfoWidget(String top, String bottom, var context) {
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
