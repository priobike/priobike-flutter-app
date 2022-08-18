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
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/settings/service.dart';
import 'package:priobike/settings/views/main.dart';
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
    ChangeNotifierProvider<SettingsService>(
      create: (context) => SettingsService(),
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
  late ProfileService profileService;

  /// The associated settings service, which is injected by the provider.
  late SettingsService settingsService;

  /// The associated shortcuts service, which is injected by the provider.
  late ShortcutsService shortcutsService;

  /// The associated routing service, which is injected by the provider.
  late RoutingService routingService;

  @override
  void didChangeDependencies() {
    profileService = Provider.of<ProfileService>(context);
    settingsService = Provider.of<SettingsService>(context);
    shortcutsService = Provider.of<ShortcutsService>(context);
    routingService = Provider.of<RoutingService>(context);

    // Load once the window was built.
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await settingsService.loadSettings();
      await profileService.loadProfile();
      await shortcutsService.loadShortcuts(context);
    });

    super.didChangeDependencies();
  }

  /// A callback that is fired when the settings button is tapped.
  void onSettingsButtonTapped() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return const Scaffold(body: SettingsView());
    }));
  }

  /// A callback that is fired when a shortcut was selected.
  void onSelectShortcut(Shortcut shortcut) {
    routingService.selectWaypoints(shortcut.waypoints);
    routingService.loadRoutes(context);

    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return const Scaffold(body: RoutingView());
    }));
  }

  @override 
  Widget build(BuildContext context) {
    return Fade(child: SingleChildScrollView(
      child: Column(children: [
        const SizedBox(height: 128),
        NavBarView(
          onTapNotificationButton: () => ToastMessage.showError("News sind noch nicht verfügbar."),
          onTapSettingsButton: onSettingsButtonTapped,
        ),
        const Divider(color: AppColors.lightGrey, thickness: 2),
        const VSpace(),
        HPad(child: BoldContent(text: "Shortcuts und Radfahrprofil")),
        const VSpace(),
        ShortcutsView(onSelectShortcut: onSelectShortcut),
        const VSpace(),
        const ProfileView(),
        const VSpace(),
        const SmallVSpace(),
        const Divider(color: AppColors.lightGrey, thickness: 2),
        const VSpace(),
        const SizedBox(height: 128),
      ])
    ));
  }
}