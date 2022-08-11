

import 'package:flutter/material.dart';
import 'package:priobike/v2/common/colors.dart';
import 'package:priobike/v2/common/debug.dart';
import 'package:priobike/v2/common/fx.dart';
import 'package:priobike/v2/common/layout/spacing.dart';
import 'package:priobike/v2/common/layout/text.dart';
import 'package:priobike/v2/home/models/shortcut.dart';
import 'package:priobike/v2/home/services/profile.dart';
import 'package:priobike/v2/home/services/shortcuts.dart';
import 'package:priobike/v2/home/views/nav.dart';
import 'package:priobike/v2/home/views/profile.dart';
import 'package:priobike/v2/home/views/shortcuts.dart';
import 'package:priobike/v2/routing/services/routing.dart';
import 'package:priobike/v2/routing/views/main.dart';
import 'package:priobike/v2/session/services/session.dart';
import 'package:provider/provider.dart';

/// Debug these views.
void main() => debug(MultiProvider(
  providers: [
    ChangeNotifierProvider<ShortcutsService>(
      create: (context) => ShortcutsService(),
    ),
    ChangeNotifierProvider<ProfileService>(
      create: (context) => ProfileService(),
    ),
  ],
  child: const HomeView(),
));

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override 
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  /// The associated profile service, which is injected by the provider.
  late ProfileService ps;

  /// The associated shortcuts service, which is injected by the provider.
  late ShortcutsService ss;

  @override
  void didChangeDependencies() {
    ps = Provider.of<ProfileService>(context);
    ss = Provider.of<ShortcutsService>(context);
    super.didChangeDependencies();
  }

  /// A callback that is fired when a shortcut was selected.
  void onSelectShortcut(Shortcut shortcut) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Scaffold(body: MultiProvider(
        providers: [
          // Create the session service.
          ChangeNotifierProvider<SessionService>(
            create: (context) => ProductionSessionService(),
          ),
          // Create the routing service with the waypoints.
          ChangeNotifierProvider<RoutingService>(create: (context) => RoutingService(
            selectedWaypoints: shortcut.waypoints
          )),
        ],
        child: const RoutingView(),
      ));
    }));
  }

  @override 
  Widget build(BuildContext context) {
    return Fade(child: SingleChildScrollView(
      child: Column(children: [
        const SizedBox(height: 128),
        const NavBarView(),
        const Divider(color: AppColors.lightGrey, thickness: 2),
        const VSpace(),
        HPad(child: BoldContent(text: "Shortcuts und Radfahrprofil")),
        const VSpace(),
        ShortcutsView(onSelectShortcut: onSelectShortcut),
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