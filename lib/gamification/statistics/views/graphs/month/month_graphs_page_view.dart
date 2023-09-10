import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/views/graphs/ride_graphs_page_view.dart';
import 'package:priobike/gamification/statistics/services/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/views/graphs/month/month_graph.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/main.dart';

/// This widget shows detailed statistics for the last 6 months, using the [RideGraphsPageView] widget.
class MonthGraphsPageView extends StatefulWidget {
  final StatisticService statsService;

  const MonthGraphsPageView({Key? key, required this.statsService}) : super(key: key);

  @override
  State<MonthGraphsPageView> createState() => _MonthGraphsPageViewState();
}

class _MonthGraphsPageViewState extends State<MonthGraphsPageView> {
  static const int numOfPages = 6;

  late PageController pageController;

  List<MonthStatsViewModel> viewModels = [];

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
    var month = DateTime.now().month;
    var year = DateTime.now().year;

    for (int i = 0; i < numOfPages; i++) {
      var viewModel = MonthStatsViewModel(year, month);
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
      vm.setRideInfoType(widget.statsService.rideInfo);
    }
    return RideGraphsPageView(
      pageController: pageController,
      graphs: viewModels.map((vm) => MonthStatsGraph(viewModel: vm)).toList(),
      currentViewModel: viewModels.elementAt(displayedPageIndex),
    );
  }
}
