import 'package:flutter/material.dart';
import 'package:priobike/gamification/statistics/graphs/compact_labled_graph.dart';
import 'package:priobike/gamification/statistics/graphs/graph_viewmodels.dart';
import 'package:priobike/gamification/statistics/graphs/month/month_graph.dart';
import 'package:priobike/gamification/statistics/views/utils.dart';

class CompactMonthStatsGraph extends StatefulWidget {
  final Function() tabHandler;

  const CompactMonthStatsGraph({Key? key, required this.tabHandler}) : super(key: key);

  @override
  State<CompactMonthStatsGraph> createState() => _CompactMonthStatsGraphState();
}

class _CompactMonthStatsGraphState extends State<CompactMonthStatsGraph> {
  late MonthGraphViewModel viewModel;

  void update() => setState(() {});

  @override
  void initState() {
    viewModel = MonthGraphViewModel(2023, 8);
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
      subTitle: getSubTitle(),
      title: 'Dieser Monat',
      graph: MonthStatsGraph(
        tabHandler: widget.tabHandler,
        viewModel: viewModel,
      ),
    );
  }

  String getInfoText() {
    if (viewModel.yValues.isEmpty) {
      return '';
    } else if (viewModel.selectedIndex == null) {
      return '${StatUtils.getListSumStr(viewModel.yValues)} km';
    } else {
      return '${StatUtils.convertDoubleToStr(viewModel.yValues[viewModel.selectedIndex!])} km';
    }
  }

  String getSubTitle() {
    return (viewModel.selectedIndex == null ? '' : '${viewModel.selectedIndex}. ') +
        StatUtils.getMonthStr(viewModel.month);
  }
}
