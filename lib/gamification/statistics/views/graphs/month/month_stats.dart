import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/views/graphs/detailed_statistics.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/views/graphs/month/month_graph.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/main.dart';

/// This widget shows detailed statistics for the last 6 months, using the [DetailedStatistics] widget.
class DetailedMonthStats extends StatefulWidget {
  final AnimationController headerAnimationController;

  final AnimationController rideListController;

  const DetailedMonthStats({
    Key? key,
    required this.headerAnimationController,
    required this.rideListController,
  }) : super(key: key);

  @override
  State<DetailedMonthStats> createState() => _DetailedMonthStatsState();
}

class _DetailedMonthStatsState extends State<DetailedMonthStats> {
  static int numOfPages = 6;

  late PageController pageController;

  List<MonthGraphViewModel> viewModels = [];

  int displayedPageIndex = numOfPages - 1;

  void update() => setState(() {});

  @override
  void initState() {
    createViewModels();
    super.initState();
  }

  @override
  void dispose() {
    for (var vm in viewModels) {
      vm.endStreams();
    }
    pageController.dispose();
    super.dispose();
  }

  void createViewModels() {
    var month = DateTime.now().month;
    var year = DateTime.now().year;

    for (int i = 0; i < numOfPages; i++) {
      var viewModel = MonthGraphViewModel(year, month);
      viewModel.startStreams();
      viewModel.addListener(() => update());
      viewModels.add(viewModel);
      if (month == 1) {
        month = 12;
        year -= 1;
      } else {
        month -= 1;
      }
    }
    viewModels = viewModels.reversed.toList();
    pageController = PageController(initialPage: viewModels.length - 1);
    pageController.addListener(() {
      if (pageController.page == null) return;
      var prevIndex = displayedPageIndex;
      displayedPageIndex = pageController.page!.round();
      if (displayedPageIndex != prevIndex) {
        viewModels[prevIndex].setSelectedIndex(null);
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (viewModels.isEmpty) return const SizedBox.shrink();
    for (var vm in viewModels) {
      vm.setRideInfoType(getIt<StatisticService>().rideInfo);
    }
    return DetailedStatistics(
      pageController: pageController,
      graphs: viewModels
          .map((vm) => MonthStatsGraph(
                tabHandler: () {},
                viewModel: vm,
              ))
          .toList(),
      currentViewModel: viewModels.elementAt(displayedPageIndex),
      headerAnimationController: widget.headerAnimationController,
      rideListController: widget.rideListController,
    );
  }
}
