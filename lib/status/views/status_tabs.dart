import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/status/views/status.dart';
import 'package:priobike/status/views/status_history.dart';

enum StatusHistoryTime {
  day,
  week,
}

extension StatusHistoryTimeName on StatusHistoryTime {
  String name() {
    switch (this) {
      case StatusHistoryTime.day:
        return "24 Stunden";
      case StatusHistoryTime.week:
        return "7 Tage";
    }
  }
}

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

  /// The prediction status service, which is injected by the provider.
  final PredictionStatusSummary predictionStatusSummary = getIt<PredictionStatusSummary>();

  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // tabController with number of articles.
    tabController = TabController(length: 3, vsync: this);
    predictionStatusSummary.addListener(update);
  }

  @override
  void dispose() {
    tabController?.dispose();
    pageController.dispose();
    predictionStatusSummary.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      "Jetzt",
      "24 Stunden",
      "7 Tage",
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        SizedBox(
          height: 130,
          width: MediaQuery.of(context).size.width,
          child: PageView(
            controller: pageController,
            clipBehavior: Clip.none,
            onPageChanged: (int index) {
              setState(() {
                tabController?.index = index;
              });
            },
            children: const [
              StatusView(),
              StatusHistoryView(time: StatusHistoryTime.day),
              StatusHistoryView(time: StatusHistoryTime.week),
            ],
          ),
        ),
        const SmallVSpace(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...buttons.map(
              (e) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Tile(
                  onPressed: () => pageController.animateTo(
                      ((MediaQuery.of(context).size.width - 40) * buttons.indexOf(e)),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut),
                  fill: tabController?.index == buttons.indexOf(e)
                      ? (predictionStatusSummary.getProblem() != null ? CI.red : Theme.of(context).colorScheme.primary)
                      : Theme.of(context).colorScheme.background,
                  splash: Theme.of(context).brightness == Brightness.light ? Colors.grey : Colors.white,
                  shadowIntensity: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  borderRadius: BorderRadius.circular(12),
                  content: Center(
                    child: Content(
                      context: context,
                      text: e,
                      color: tabController?.index == buttons.indexOf(e) || isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
