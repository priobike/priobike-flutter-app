import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/graphs/compact_labled_graph.dart';
import 'package:priobike/gamification/statistics/graphs/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/graphs/week/week_graph.dart';

class CompactWeekGraph extends StatefulWidget {
  final Function() tabHandler;

  const CompactWeekGraph({Key? key, required this.tabHandler}) : super(key: key);

  @override
  State<CompactWeekGraph> createState() => _CompactWeekGraphState();
}

class _CompactWeekGraphState extends State<CompactWeekGraph> {
  late WeekGraphViewModel viewModel;

  void update() => setState(() {});

  @override
  void initState() {
    viewModel = WeekGraphViewModel(DateTime(2023, 8, 14));
    viewModel.startStreams();
    viewModel.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    viewModel.endStreams();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompactGraph(
      infoText: viewModel.selectedOrOverallValueStr,
      subTitle: viewModel.rangeOrSelectedDateStr,
      title: 'Diese Woche',
      graph: WeekStatsGraph(
        tabHandler: widget.tabHandler,
        viewModel: viewModel,
      ),
    );
  }
}
