import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/graphs/detailed_labled_graph.dart';
import 'package:priobike/gamification/statistics/graphs/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/graphs/week/week_graph.dart';

class DetailedWeekGraph extends StatefulWidget {
  const DetailedWeekGraph({Key? key}) : super(key: key);

  @override
  State<DetailedWeekGraph> createState() => _DetailedWeekGraphState();
}

class _DetailedWeekGraphState extends State<DetailedWeekGraph> {
  late PageController pageController;

  List<WeekGraphViewModel> viewModels = [];

  int displayedPageIndex = 0;

  void update() => setState(() {});

  @override
  void initState() {
    createViewModels(10);
    super.initState();
  }

  void createViewModels(int numOfWeeks) {
    var today = DateTime.now();
    var weekStart = today.subtract(Duration(days: today.weekday - 1));
    weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
    for (int i = 0; i < numOfWeeks; i++) {
      var tmpWeekStart = weekStart.subtract(Duration(days: 7 * i));
      var viewModel = WeekGraphViewModel(tmpWeekStart);
      viewModel.startStreams();
      viewModel.addListener(() => update());
      viewModels.add(viewModel);
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
  void dispose() {
    for (var vm in viewModels) {
      vm.endStreams();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (viewModels.isEmpty) return const SizedBox.shrink();
    return DetailedGraph(
      pageController: pageController,
      graphs: viewModels
          .map((vm) => WeekStatsGraph(
                tabHandler: () {},
                viewModel: vm,
              ))
          .toList(),
      graphInfo: viewModels.elementAt(displayedPageIndex).getRangeOrSelectedDateStr(),
    );
  }
}
