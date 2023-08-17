import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/statistics/graphs/graph_viewmodels.dart';

class CompactGraph extends StatelessWidget {
  final GraphViewModel viewModel;
  final String title;
  final Widget graph;

  const CompactGraph({
    Key? key,
    required this.viewModel,
    required this.title,
    required this.graph,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BoldContent(
                    text: title,
                    context: context,
                    textAlign: TextAlign.left,
                  ),
                  Text(
                    viewModel.rangeOrSelectedDateStr,
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              Text(
                viewModel.selectedOrOverallValueStr,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: graph,
        ),
      ],
    );
  }
}
