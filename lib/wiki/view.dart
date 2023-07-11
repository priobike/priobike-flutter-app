import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
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
    tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    tabController?.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BoldContent(
              text: "Wie funktioniert PrioBike?",
              context: context,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Small(
              text: "Erfahre mehr über die App.",
              context: context,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 164,
        child: PageView(
          controller: pageController,
          clipBehavior: Clip.none,
          onPageChanged: (int index) {
            setState(() {
              tabController?.index = index;
            });
          },
          children: [
            WikiCard(article: articlePrioBike),
            WikiCard(article: articleDataFailures),
            WikiCard(article: articleSwitchingPrograms),
            WikiCard(article: articleSGSelector),
          ],
        ),
      ),
      Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(top: 8),
        child: TabPageSelector(
          controller: tabController,
          selectedColor: CI.blue,
          indicatorSize: 12,
          borderStyle: BorderStyle.none,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
          key: GlobalKey(),
        ),
      ),
    ]);
  }
}
