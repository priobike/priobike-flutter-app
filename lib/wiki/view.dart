import 'package:flutter/material.dart';
import 'package:priobike/wiki/widgets/wikiCard.dart';

class WikiView extends StatefulWidget {
  const WikiView({Key? key}) : super(key: key);

  @override
  WikiViewState createState() => WikiViewState();
}

class WikiViewState extends State<WikiView> {
  /// PageController.
  final PageController pageController = PageController(
    viewportFraction: 0.85,
    initialPage: 0,
  );

  /// Int that holds the state of the current page.
  int currentPage = 0;

  int articles = 3;

  /// Widget that displays the current page.
  Widget _pageIndicator() {
    List<Widget> indicators = List<Widget>.generate(
      articles,
      (index) => Container(
        margin: const EdgeInsets.all(2.5),
        width: 15,
        height: 15,
        decoration: BoxDecoration(
            color: currentPage == index ? Colors.lightBlue : Colors.grey,
            shape: BoxShape.circle),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: indicators,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 225,
      child: Column(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 200,
            child: PageView(
              controller: pageController,
              onPageChanged: (int index) {
                setState(() {
                  currentPage = index;
                });
              },
              children: const [
                WikiCard(
                  title: "First",
                  subTitle: "first",
                ),
                WikiCard(
                  title: "Second",
                  subTitle: "second",
                ),
                WikiCard(
                  title: "Second",
                  subTitle: "second",
                ),
              ],
            ),
          ),
          _pageIndicator(),
        ],
      ),
    );
  }
}
