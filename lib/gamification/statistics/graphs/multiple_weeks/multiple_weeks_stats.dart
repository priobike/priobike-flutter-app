import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/graphs/detailed_labled_graph.dart';
import 'package:priobike/gamification/statistics/graphs/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/graphs/multiple_weeks/multiple_weeks_graph.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/main.dart';

class DetailedMultipleWeekStats extends StatefulWidget {
  final AnimationController animationController;

  const DetailedMultipleWeekStats({Key? key, required this.animationController}) : super(key: key);

  @override
  State<DetailedMultipleWeekStats> createState() => _DetailedMultipleWeekStatsState();
}

class _DetailedMultipleWeekStatsState extends State<DetailedMultipleWeekStats> {
  static int numOfPages = 5;

  late PageController pageController;

  List<MultipleWeeksGraphViewModel> viewModels = [];

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
    var today = DateTime.now();
    var weekStart = today.subtract(Duration(days: today.weekday - 1));
    weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
    for (int i = 0; i < numOfPages; i++) {
      var viewModel = MultipleWeeksGraphViewModel(weekStart, 5);
      viewModel.startStreams();
      viewModel.addListener(() => update());
      viewModels.add(viewModel);
      weekStart = weekStart.subtract(Duration(days: 7 * numOfPages));
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
      vm.setRideInfoType(getIt<StatisticService>().selectedRideInfo);
    }
    return DetailedGraph(
      pageController: pageController,
      graphs: viewModels
          .map((vm) => MultipleWeeksStatsGraph(
                tabHandler: () {},
                viewModel: vm,
              ))
          .toList(),
      currentViewModel: viewModels.elementAt(displayedPageIndex),
      animationController: widget.animationController,
    );
  }
}
