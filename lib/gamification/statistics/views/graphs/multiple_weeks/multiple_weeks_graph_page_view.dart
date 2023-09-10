import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/views/graphs/ride_graphs_page_view.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/views/graphs/multiple_weeks/multiple_weeks_graph.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/main.dart';

/// This widget shows detailed statistics for the last 5  5-week intervals, using the [RideGraphsPageView] widget.
class MultipleWeeksGraphsPageView extends StatefulWidget {
  final StatisticService statsService;

  const MultipleWeeksGraphsPageView({Key? key, required this.statsService}) : super(key: key);

  @override
  State<MultipleWeeksGraphsPageView> createState() => _MultipleWeeksGraphsPageViewState();
}

class _MultipleWeeksGraphsPageViewState extends State<MultipleWeeksGraphsPageView> {
  static const int numOfPages = 5;

  late PageController pageController;

  List<MultipleWeeksStatsViewModel> viewModels = [];

  int displayedPageIndex = numOfPages - 1;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

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
      var viewModel = MultipleWeeksStatsViewModel(weekStart, 5);
      viewModel.startStreams();
      viewModel.addListener(() => update());
      viewModels.add(viewModel);
      weekStart = weekStart.subtract(const Duration(days: 7 * numOfPages));
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
      vm.setRideInfoType(widget.statsService.rideInfo);
    }
    return RideGraphsPageView(
      pageController: pageController,
      graphs: viewModels.map((vm) => MultipleWeeksStatsGraph(viewModel: vm)).toList(),
      currentViewModel: viewModels.elementAt(displayedPageIndex),
    );
  }
}
