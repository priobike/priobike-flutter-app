import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/graphs/compact_labled_graph.dart';
import 'package:priobike/gamification/statistics/graphs/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/graphs/multiple_weeks/multiple_weeks_graph.dart';
import 'package:priobike/gamification/statistics/views/utils.dart';

class CompactMultipleWeeksGraph extends StatefulWidget {
  final Function() tabHandler;

  const CompactMultipleWeeksGraph({Key? key, required this.tabHandler}) : super(key: key);

  @override
  State<CompactMultipleWeeksGraph> createState() => _CompactMultipleWeeksGraphState();
}

class _CompactMultipleWeeksGraphState extends State<CompactMultipleWeeksGraph> {
  late MultipleWeeksGraphViewModel viewModel;

  void update() => setState(() {});

  @override
  void initState() {
    viewModel = MultipleWeeksGraphViewModel(DateTime(2023, 8, 14), 5);
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
      infoText: getInfoText(),
      subTitle: viewModel.getRangeOrWeekStr(),
      title: 'Letzten 5 Wochen',
      graph: MultipleWeeksStatsGraph(
        tabHandler: widget.tabHandler,
        viewModel: viewModel,
      ),
    );
  }

  String getInfoText() {
    if (viewModel.yValues.isEmpty) return '';
    if (viewModel.selectedIndex == null) return '${StatUtils.getListSumStr(viewModel.yValues)} km';
    return '${StatUtils.convertDoubleToStr(viewModel.yValues[viewModel.selectedIndex!])} km';
  }
}
