import 'package:flutter/material.dart';
import 'package:priobike/common/layout/images.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:provider/provider.dart';

/// A view that displays alerts in the routing context.
class AlertsView extends StatefulWidget {
  const AlertsView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AlertsViewState();
}

class AlertsViewState extends State<AlertsView> {
  /// The associated discomfort service, which is injected by the provider.
  late DiscomfortService discomfortService;

  /// The associated routing service, which is injected by the provider.
  late RoutingService routingService;

  /// The controller for the carousel.
  final controller = PageController();

  @override
  void didChangeDependencies() {
    discomfortService = Provider.of<DiscomfortService>(context);
    routingService = Provider.of<RoutingService>(context);

    // Scroll to a discomfort if one was selected.
    if (discomfortService.selectedDiscomfort != null) {
      final discomforts = discomfortService.foundDiscomforts;
      if (discomforts != null && discomforts.isNotEmpty) {
        for (int i = 0; i < discomforts.length; i++) {
          if (discomforts[i] == discomfortService.selectedDiscomfort) {
            controller.jumpToPage(i);
            break;
          }
        }
      }
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // Show nothing if there are no alerts to display.
    if (discomfortService.foundDiscomforts == null || discomfortService.foundDiscomforts!.isEmpty) return Container();

    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 22), child: Container(
          height: 64,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 255, 0, 0),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.0),
              bottomLeft: Radius.circular(24.0),
            ),
          ),
          child: renderCarousel(context),
        )),
        Padding(padding: const EdgeInsets.only(right: 0), child: Container(
          height: 28,
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.0),
              bottomLeft: Radius.circular(24.0),
            ),
          ),
          child: BoldSmall(text: discomfortService.foundDiscomforts!.length > 1
              ? "${discomfortService.foundDiscomforts!
              .length} Hinweise zu deiner Route"
              : "1 Hinweis zu deiner Route", context: context),
        ),),
      ],
    );
  }

  Widget renderCarousel(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(alignment: AlignmentDirectional.topStart, children: [
          PageView(
            children: discomfortService.foundDiscomforts!.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 0), 
              child: Row(children: [
                Stack(alignment: AlignmentDirectional.center, children: [
                  const AlertIcon(width: 42, height: 42),
                  BoldContent(text: "${e.key + 1}", context: context),
                ]),
                const SmallHSpace(),
                SizedBox(
                  width: constraints.maxWidth - 112,
                  height: constraints.maxHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                      Flexible(child: BoldSmall(text: e.value.description, maxLines: 3, color: Colors.white, context: context)),
                    ],
                  ),
                ),
              ]))
            ).toList(),
            controller: controller,
            onPageChanged: (index) { /* Do nothing */ }, 
          ),
        ]);
      },
    );
  }
}