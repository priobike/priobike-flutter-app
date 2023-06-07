import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/status/views/status.dart';
import 'package:priobike/status/views/status_history.dart';

class StatusTabsView extends StatefulWidget {
  const StatusTabsView({Key? key}) : super(key: key);

  @override
  StatusTabsViewState createState() => StatusTabsViewState();
}

class StatusTabsViewState extends State<StatusTabsView> with SingleTickerProviderStateMixin {
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
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 164,
        child: PageView(
          controller: pageController,
          onPageChanged: (int index) {
            setState(() {
              tabController?.index = index;
            });
          },
          children: const [
            StatusView(),
            StatusHistoryView(),
            StatusHistoryView(),
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
