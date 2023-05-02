import 'package:flutter/material.dart';

class WikiDetailView extends StatefulWidget {
  const WikiDetailView({Key? key}) : super(key: key);

  @override
  WikiDetailViewState createState() => WikiDetailViewState();
}

class WikiDetailViewState extends State<WikiDetailView> {
  /// PageController.
  final PageController pageController = PageController();

  /// Int that holds the state of the current page.
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageView(
          controller: pageController,
          children: [],
        ),
        Container(),
      ],
    );
  }
}
