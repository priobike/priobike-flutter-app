import 'package:flutter/material.dart';
import 'package:priobike/wiki/articles.dart';
import 'package:priobike/wiki/widgets/wiki_card.dart';

class WikiView extends StatefulWidget {
  const WikiView({Key? key}) : super(key: key);

  @override
  WikiViewState createState() => WikiViewState();
}

class WikiViewState extends State<WikiView> with SingleTickerProviderStateMixin {
  /// PageController.
  final PageController pageController = PageController(
    viewportFraction: 0.9,
    initialPage: 0,
  );

  /// TabController.
  late TabController? tabController;

  @override
  void initState() {
    super.initState();
    // tabController with number of articles.
    tabController = TabController(length: 4, vsync: this, animationDuration: const Duration(milliseconds: 2000));
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
                  tabController?.index = index;
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
            child: TabPageSelector(
              controller: tabController,
              selectedColor: Theme.of(context).colorScheme.primary,
              borderStyle: BorderStyle.none,
              color: Colors.grey,
              key: GlobalKey(),
            ),
          ),
        ],
      ),
    );
  }
}
