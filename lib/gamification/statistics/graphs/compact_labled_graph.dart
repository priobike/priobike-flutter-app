import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';

class CompactGraph extends StatelessWidget {
  final String title;
  final String subTitle;
  final String infoText;
  final Widget graph;

  const CompactGraph({
    Key? key,
    required this.graph,
    required this.title,
    required this.subTitle,
    required this.infoText,
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
                    subTitle,
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              Text(
                infoText,
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
