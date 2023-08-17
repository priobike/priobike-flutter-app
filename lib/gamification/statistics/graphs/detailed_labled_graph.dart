import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/statistics/graphs/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/main.dart';

class DetailedGraph extends StatelessWidget {
  final PageController pageController;

  final List<Widget> graphs;

  final GraphViewModel currentViewModel;

  const DetailedGraph({
    Key? key,
    required this.graphs,
    required this.pageController,
    required this.currentViewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            text: isAvg
                ? (noSelectedBar ? ' ' : 'ø ${currentViewModel.selectedOrOverallValueStr}')
                : currentViewModel.selectedOrOverallValueStr,
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
}
