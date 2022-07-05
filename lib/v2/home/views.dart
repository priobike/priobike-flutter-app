

import 'package:flutter/material.dart';
import 'package:priobike/v2/common/colors.dart';
import 'package:priobike/v2/common/debug.dart';
import 'package:priobike/v2/common/views.dart';

/// Debug these views.
void main() => debug(const HomeView());

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override 
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  @override 
  Widget build(BuildContext context) {
    return Column(children: [
      Container(padding: const EdgeInsets.only(left: 24), child: Column(children: [
        const SizedBox(height: 128),
        Row(children: [
          const Icon(
            Icons.sunny_snowing,
            size: 32,
            color: Colors.black
          ),
          const SmallHSpace(),
          Flexible(child: Small(text: "Wetterwarnung: Ab 13 Uhr könnte es in Hamburg schneien.")),
          const SmallHSpace(),
          SmallIconButton(icon: Icons.notifications, onPressed: () {}),
          const SmallHSpace(),
          SmallIconButton(icon: Icons.settings, onPressed: () {}),
          const HSpace(),
        ]),
        const SmallVSpace(),
        Divider(color: AppColors.lightGrey, thickness: 2),
      ])),
      const SmallVSpace(),
      SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24),
        scrollDirection: Axis.horizontal, 
        child: Row(children: [
          Container(
            alignment: Alignment.centerLeft,
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 200),
            padding: const EdgeInsets.only(right: 16),
            child: ColorTile(
              onPressed: () {},
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.route,
                    size: 64,
                    color: Colors.white,
                  ),
                  SubHeader(text: "Routing starten", color: Colors.white),
                ],
              ),
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 200),
            padding: const EdgeInsets.only(right: 16),
            child: Tile(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.route,
                    size: 64,
                    color: Colors.black,
                  ),
                  SubHeader(text: "Nach Hause"),
                ],
              ),
            ),
          ),
        ])
      ),
    ]);
  }
}