

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:priobike/v2/common/layout/images.dart';
import 'package:priobike/v2/common/layout/spacing.dart';
import 'package:priobike/v2/common/layout/text.dart';
import 'package:priobike/v2/routing/models/discomfort.dart';

/// A view that displays alerts in the routing context.
class AlertsView extends StatefulWidget {
  /// The discomforts to show as alerts in this view.
  final List<Discomfort>? discomforts;

  const AlertsView({required this.discomforts, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AlertsViewState();
}

class AlertsViewState extends State<AlertsView> {
  /// The currently selected alerts page.
  var current = 0;

  /// The controller for the carousel.
  final controller = CarouselController();

  @override
  Widget build(BuildContext context) {
    // Show nothing if there are no alerts to display.
    if (widget.discomforts == null || widget.discomforts!.isEmpty) return Container();

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          bottomLeft: Radius.circular(24.0),
        ),
      ),
      child: renderCarousel(context),
    );
  }

  Widget renderCarousel(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(alignment: AlignmentDirectional.topStart, children: [
          CarouselSlider(
            items: widget.discomforts!.asMap().entries.map((e) => Padding(
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
                      Flexible(child: Small(text: e.value.description, maxLines: 3)),
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
              onPageChanged: (index, reason) {
                setState(() { current = index; });
              }
            ),
          ),
        ]);
      },
    );
  }
}