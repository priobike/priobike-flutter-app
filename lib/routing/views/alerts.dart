import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/images.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:provider/provider.dart';

/// A view that displays alerts in the routing context.
class AlertsView extends StatefulWidget {
  const AlertsView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AlertsViewState();
}

class AlertsViewState extends State<AlertsView> {
  /// The associated routing service, which is injected by the provider.
  late RoutingService s;

  /// The controller for the carousel.
  final controller = CarouselController();

  @override
  void didChangeDependencies() {
    s = Provider.of<RoutingService>(context);

    // Scroll to a discomfort if one was selected.
    if (s.selectedDiscomfort != null) {
      final discomforts = s.selectedRoute?.discomforts;
      if (discomforts != null && discomforts.isNotEmpty) {
        for (int i = 0; i <= discomforts.length; i++) {
          if (discomforts[i] == s.selectedDiscomfort) {
            controller.animateToPage(i);
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
    if (s.selectedRoute?.discomforts == null || s.selectedRoute!.discomforts!.isEmpty) return Container();

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
          child: BoldSmall(text: "Hinweise"),
        )),
      ],
    );
  }

  Widget renderCarousel(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(alignment: AlignmentDirectional.topStart, children: [
          CarouselSlider(
            items: s.selectedRoute!.discomforts!.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 0), 
              child: Row(children: [
                Stack(alignment: AlignmentDirectional.center, children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 3, bottom: 3),
                    child: AlertIcon(),
                  ),
                  BoldSmall(text: "${e.key + 1}"),
                ]),
                const SmallHSpace(),
                SizedBox(
                  width: constraints.maxWidth - 112,
                  height: constraints.maxHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                      Flexible(child: BoldSmall(text: e.value.description, maxLines: 3, color: Colors.white)),
                    ],
                  ),
                ),
              ]))
            ).toList(),
            carouselController: controller,
            options: CarouselOptions(
              enlargeCenterPage: true,
              padEnds: false,
              aspectRatio: constraints.maxWidth / constraints.maxHeight,
              onPageChanged: (index, reason) { /* Do nothing */ },
            ),
          ),
        ]);
      },
    );
  }
}