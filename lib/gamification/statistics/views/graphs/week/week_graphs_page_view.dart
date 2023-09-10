import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/views/graphs/ride_graphs_page_view.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/views/graphs/week/week_graph.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';

/// This widget shows detailed statistics for the last 10 weeks, using the [RideGraphsPageView] widget.
class WeekGraphsPageView extends StatefulWidget {
  final StatisticService statsService;

  const WeekGraphsPageView({Key? key, required this.statsService}) : super(key: key);

  @override
  State<WeekGraphsPageView> createState() => _WeekGraphsPageViewState();
}

class _WeekGraphsPageViewState extends State<WeekGraphsPageView> {
  static const int numOfPages = 10;

  late PageController pageController;

  List<WeekStatsViewModel> viewModels = [];

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
    for (int i = 0; i < numOfPages; i++) {
      var tmpWeekStart = weekStart.subtract(Duration(days: 7 * i));
      var viewModel = WeekStatsViewModel(tmpWeekStart);
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
  Widget build(BuildContext context) {
    if (viewModels.isEmpty) return const SizedBox.shrink();
    for (var vm in viewModels) {
      vm.setRideInfoType(widget.statsService.rideInfo);
    }
    return RideGraphsPageView(
      pageController: pageController,
      graphs: viewModels.map((vm) => WeekStatsGraph(viewModel: vm)).toList(),
      currentViewModel: viewModels.elementAt(displayedPageIndex),
    );
  }
}
