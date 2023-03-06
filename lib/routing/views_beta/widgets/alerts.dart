import 'package:flutter/material.dart';
import 'package:priobike/common/layout/images.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/status/services/sg.dart';

/// A view that displays alerts in the routing context.
class AlertsView extends StatefulWidget {
  const AlertsView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AlertsViewState();
}

class AlertsViewState extends State<AlertsView> {
  /// The associated sg status service, which is injected by the provider.
  late PredictionSGStatus predictionStatus;

  /// The associated discomfort service, which is injected by the provider.
  late Discomforts discomforts;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The controller for the carousel.
  final controller = PageController();

  /// The currently selected page.
  int currentPage = 0;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    scrollToDiscomfort();
    setState(() {});
  }

  /// Scroll to a discomfort if one was selected.
  void scrollToDiscomfort() {
    if (discomforts.selectedDiscomfort != null &&
        discomforts.foundDiscomforts != null &&
        discomforts.foundDiscomforts!.isNotEmpty) {
      for (int i = 0; i < discomforts.foundDiscomforts!.length; i++) {
        if (discomforts.foundDiscomforts![i] == discomforts.selectedDiscomfort) {
          // Add offset if prediction error is displayed.
          if (predictionStatus.bad != 0 || predictionStatus.offline != 0 || predictionStatus.disconnected != 0) {
            i += 1;
          }
          if (controller.hasClients) {
            controller.jumpToPage(i);
          }
          setState(() {
            currentPage = i;
          });
          break;
        }
      }
    }

    // Case trafficLightClicked when alerts open.
    if (discomforts.trafficLightClicked) {
      if (controller.hasClients) {
        controller.jumpToPage(0);
      }
      setState(() {
        currentPage = 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    predictionStatus = getIt<PredictionSGStatus>();
    predictionStatus.addListener(update);
    discomforts = getIt<Discomforts>();
    discomforts.addListener(update);
    routing = getIt<Routing>();
    routing.addListener(update);

    scrollToDiscomfort();
  }

  @override
  void dispose() {
    predictionStatus.removeListener(update);
    discomforts.removeListener(update);
    routing.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      final alerts = [
        ...renderSignalAlerts(context, constraints),
        ...renderComfortAlerts(context, constraints),
      ];
      if (alerts.isEmpty) return Container();

      return Stack(
        alignment: AlignmentDirectional.bottomEnd,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24.0),
                  bottomRight: Radius.circular(24.0),
                ),
              ),
              child: PageView(
                controller: controller,
                onPageChanged: (index) => setState(
                  () {
                    currentPage = index;
                  },
                ),
                children: alerts,
              ),
            ),
          ),
          // Show dots to indicate the current page.
          if (alerts.length > 1)
            Positioned(
              bottom: 26,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < alerts.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == currentPage
                              ? Colors.red
                              : Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    });
  }

  /// Render signal alerts.
  List<Widget> renderSignalAlerts(BuildContext context, BoxConstraints constraints) {
    if (routing.isFetchingRoute || predictionStatus.isLoading) return [];
    if (predictionStatus.bad == 0 && predictionStatus.offline == 0 && predictionStatus.disconnected == 0) return [];
    final sum = predictionStatus.bad + predictionStatus.offline + predictionStatus.disconnected;
    return [
      Padding(
        padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2, right: 16),
        child: Row(
          children: [
            SizedBox(
              width: constraints.maxWidth - 32,
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.headlineMedium,
                      children: [
                        const TextSpan(text: "Diese Route enthält "),
                        if (predictionStatus.offline > 0 || predictionStatus.bad > 0) ...[
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const OfflineIcon(
                                height: 8,
                                width: 8,
                              ),
                            ),
                          ),
                          TextSpan(
                            text: " ${predictionStatus.offline + predictionStatus.bad} aktuell nicht",
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium!
                                .merge(const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                        if ((predictionStatus.offline > 0 || predictionStatus.bad > 0) &&
                            predictionStatus.disconnected > 0)
                          const TextSpan(text: " und "),
                        if (predictionStatus.disconnected > 0) ...[
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const DisconnectedIcon(
                                height: 8,
                                width: 8,
                              ),
                            ),
                          ),
                          TextSpan(
                            text: " ${predictionStatus.disconnected} gar nicht",
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium!
                                .merge(const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                        const TextSpan(text: " vorhersagbare "),
                        if (sum == 1) const TextSpan(text: "Ampel."),
                        if (sum > 1) const TextSpan(text: "Ampeln."),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
    ];
  }

  /// Render comfort alerts
  List<Widget> renderComfortAlerts(BuildContext context, BoxConstraints constraints) {
    if (routing.isFetchingRoute || predictionStatus.isLoading) return [];
    if (discomforts.foundDiscomforts == null) return [];
    return discomforts.foundDiscomforts!
        .asMap()
        .entries
        .map((e) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 2, bottom: 10),
              child: Row(children: [
                SizedBox(
                  width: constraints.maxWidth - 62,
                  height: constraints.maxHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: BoldSmall(text: e.value.description, maxLines: 3, context: context)),
                    ],
                  ),
                ),
                Stack(alignment: AlignmentDirectional.center, children: [
                  const AlertIcon(width: 30, height: 30),
                  BoldContent(text: "${e.key + 1}", context: context, color: Colors.black),
                ]),
              ]),
            ))
        .toList();
  }
}
