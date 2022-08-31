

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';

class SelectionView extends StatelessWidget {
  const SelectionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HPad(child: Header(text: "Wähle eine Fahrtansicht.", color: Theme.of(context).colorScheme.primary)),
            const SmallVSpace(),
            HPad(child: SubHeader(text: "Keine Sorge, durch Wischen kannst du immer zwischen den Ansichten wechseln.")),
            GridView.count(
              primary: false,
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              crossAxisCount: 2,
              children: <Widget>[
                Tile(
                  fill: Theme.of(context).colorScheme.background,
                  content: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.speed, size: 32),
                      const Divider(),
                      Content(text: "Tachoansicht mit Navigation"),
                    ],
                  ),
                ),
                Tile(
                  fill: Theme.of(context).colorScheme.background,
                  content: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                        Icon(Icons.arrow_upward, size: 32),
                        Icon(Icons.arrow_downward, size: 32),
                      ]),
                      const Divider(),
                      Content(text: "Nur Langsamer/Schneller"),
                    ],
                  ),
                ),
                Tile(
                  fill: Theme.of(context).colorScheme.background,
                  content: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.av_timer, size: 32),
                        Content(text: "4s"),
                      ]),
                      const Divider(),
                      Content(text: "Nur Countdown"),
                    ],
                  ),
                ),
                Tile(
                  fill: Theme.of(context).colorScheme.background,
                  content: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.roundabout_left, size: 32),
                        Content(text: "..."),
                      ]),
                      const Divider(),
                      Content(text: "Nur Navigation von Oben"),
                    ],
                  ),
                ),
              ],
            ),
          ]),
        )
    );
  }
}