import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';

class DetailedGraph extends StatelessWidget {
  final PageController pageController;

  final List<Widget> graphs;

  final String graphInfo;

  const DetailedGraph({Key? key, required this.graphs, required this.pageController, required this.graphInfo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          getGraphHeader(context),
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 224,
              child: PageView(
                controller: pageController,
                clipBehavior: Clip.hardEdge,
                children: graphs,
              ),
            ),
          ),
          getGraphFooter(context),
        ],
      ),
    );
  }

  Widget getGraphHeader(var context) {
    return const SizedBox.shrink();
  }

  Widget getGraphFooter(var context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            pageController.animateToPage(
              pageController.page!.toInt() - 1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeIn,
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.arrow_back_ios),
          ),
        ),
        Expanded(
          child: SubHeader(
            text: graphInfo,
            context: context,
            textAlign: TextAlign.center,
          ),
        ),
        GestureDetector(
          onTap: () {
            pageController.animateToPage(
              pageController.page!.toInt() + 1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeIn,
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.arrow_forward_ios),
          ),
        ),
      ],
    );
  }
}
