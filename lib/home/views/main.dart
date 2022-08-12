import 'package:flutter/material.dart';
import 'package:priobike/common/colors.dart';
import 'package:priobike/common/debug.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/nav.dart';
import 'package:priobike/home/views/profile.dart';
import 'package:priobike/home/views/shortcuts.dart';
import 'package:priobike/routing/views/main.dart';
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

  /// Create the view with necessary providers from the app view hierarchy.
  static Widget withinAppHierarchy(BuildContext context) {
    return Scaffold(body: MultiProvider(
      providers: [
        ChangeNotifierProvider<ShortcutsService>(create: (c) => ShortcutsService()),
        ChangeNotifierProvider<ProfileService>(create: (c) => ProfileService()),
      ],
      child: const HomeView(),
    ));
  }

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
    // Configure the viewmodel, so that the pushed page can fetch the 
    // selected shortcut from the buildcontext.
    ss.selectedShortcut = shortcut; 

    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return RoutingView.withinAppHierarchy(context);
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