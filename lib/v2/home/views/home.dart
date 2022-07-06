

import 'package:flutter/material.dart';
import 'package:priobike/v2/common/colors.dart';
import 'package:priobike/v2/common/debug.dart';
import 'package:priobike/v2/common/views/fx.dart';
import 'package:priobike/v2/common/views/spacing.dart';
import 'package:priobike/v2/common/views/text.dart';
import 'package:priobike/v2/home/views/nav.dart';
import 'package:priobike/v2/home/views/profile.dart';
import 'package:priobike/v2/home/views/shortcuts.dart';

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
    return Fade(child: SingleChildScrollView(
      child: Column(children: [
        const SizedBox(height: 128),
        const NavBarView(),
        const Divider(color: AppColors.lightGrey, thickness: 2),
        const VSpace(),
        HPad(child: Content(text: "Shortcuts und Radfahrprofil")),
        const VSpace(),
        const ShortcutsView(),
        const VSpace(),
        const ProfileView(),
        const VSpace(),
        const Divider(color: AppColors.lightGrey, thickness: 2),
        const VSpace(),
        HPad(child: Content(text: "Weitere Inhalte sind auf dem Weg!", color: Colors.grey)),
        const SizedBox(height: 128),
      ])
    ));
  }
}