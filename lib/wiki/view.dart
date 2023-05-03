import 'package:flutter/material.dart';
import 'package:priobike/wiki/articles.dart';
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

  /// Widget that displays the current page.
  Widget _pageIndicator(int articles) {
    List<Widget> indicators = List<Widget>.generate(
      articles,
      (index) => Container(
        margin: const EdgeInsets.all(2.5),
        width: 10,
        height: 10,
        decoration: BoxDecoration(
            color: currentPage == index ? Theme.of(context).colorScheme.primary : Colors.grey, shape: BoxShape.circle),
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
      child: Stack(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 215,
            child: PageView(
              controller: pageController,
              onPageChanged: (int index) {
                setState(() {
                  currentPage = index;
                });
              },
              children: [
                WikiCard(
                  article: articleDataFailures,
                  imagePadding: 50,
                ),
                WikiCard(
                  article: articleSwitchingPrograms,
                  imagePadding: 75,
                ),
                WikiCard(
                  article: articleSGSelector,
                  imagePadding: 50,
                ),
                WikiCard(
                  article: articlePrioBike,
                  imagePadding: 55,
                ),
              ],
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 10),
            child: _pageIndicator(4),
          ),
        ],
      ),
    );
  }
}
