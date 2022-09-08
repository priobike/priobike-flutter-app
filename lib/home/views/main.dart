import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/nav.dart';
import 'package:priobike/home/views/profile.dart';
import 'package:priobike/news/service.dart';
import 'package:priobike/news/views/main.dart';
import 'package:priobike/home/views/shortcuts/edit.dart';
import 'package:priobike/home/views/shortcuts/selection.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/settings/views/main.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:priobike/tutorial/view.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override 
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  /// The associated news service, which is injected by the provider.
  late NewsService newsService;

  /// The associated profile service, which is injected by the provider.
  late ProfileService profileService;

  /// The associated settings service, which is injected by the provider.
  late SettingsService settingsService;

  /// The associated shortcuts service, which is injected by the provider.
  late ShortcutsService shortcutsService;

  /// The associated routing service, which is injected by the provider.
  late RoutingService routingService;

  /// The associated discomfort service, which is injected by the provider.
  late DiscomfortService discomfortService;

  @override
  void didChangeDependencies() {
    newsService = Provider.of<NewsService>(context);
    profileService = Provider.of<ProfileService>(context);
    settingsService = Provider.of<SettingsService>(context);
    shortcutsService = Provider.of<ShortcutsService>(context);

    routingService = Provider.of<RoutingService>(context, listen: false);
    discomfortService = Provider.of<DiscomfortService>(context, listen: false);

    // Load once the window was built.
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await newsService.getArticles(context);
      await settingsService.loadSettings();
      await profileService.loadProfile();
      await shortcutsService.loadShortcuts(context);
    });

    super.didChangeDependencies();
  }

  /// A callback that is fired when the notification button is tapped.
  void onNotificationsButtonTapped() {
    Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const NewsView()))
      .then((_) {
        // Mark all notifications as read.
        newsService.markAllArticlesAsRead();
      });
  }

  /// A callback that is fired when the settings button is tapped.
  void onSettingsButtonTapped() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsView()));
  }

  /// A callback that is fired when a shortcut was selected.
  void onSelectShortcut(Shortcut shortcut) {
    // Tell the tutorial service that the shortcut was selected.
    Provider.of<TutorialService>(context, listen: false).complete("priobike.tutorial.select-shortcut");

    routingService.selectWaypoints(shortcut.waypoints);
    routingService.loadRoutes(context);

    Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const RoutingView()))
      .then((_) {
        routingService.reset();
        discomfortService.reset();
      });
  }

  /// A callback that is fired when free routing was selected.
  void onStartFreeRouting() {
    Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const RoutingView()))
      .then((_) {
        routingService.reset();
        discomfortService.reset();
      });
  }

  /// A callback that is fired when the shortcuts should be edited.
  void onOpenShortcutEditView() {
    Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ShortcutsEditView()));
  }

  Widget renderDebugHint() {
    String? description;
    if (settingsService.backend != Backend.production) description = "Testort ist gewählt.";
    if (settingsService.positioning != Positioning.gnss) description = "Testortung ist aktiv.";
    if (description == null) return Container();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: Color.fromARGB(246, 234, 205, 100),
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: HPad(child: Row(children: [
          const Icon(Icons.warning_rounded),
          const SmallHSpace(),
          Flexible(child: Content(text: description, context: context)),
        ])),
      ),
    );
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
    body: CustomScrollView(
      slivers: <Widget>[
        NavBarView(
          onTapNotificationButton: onNotificationsButtonTapped,
          onTapSettingsButton: onSettingsButtonTapped,
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            const VSpace(),
            const SmallVSpace(),
            Row(children: [
              const HSpace(),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                BoldContent(text: "Deine Shortcuts", context: context),
                const SizedBox(height: 4),
                Small(text: "Direkt zum Ziel navigieren", context: context),
              ]),
              Expanded(child: Container()),
              SmallIconButton(
                icon: Icons.edit, 
                fill: Theme.of(context).colorScheme.background,
                splash: Colors.white,
                onPressed: onOpenShortcutEditView,
              ),
              const HSpace(),
            ]),
            const VSpace(),
            const TutorialView(
              id: "priobike.tutorial.select-shortcut", 
              text: 'Fährst du eine Route häufiger? Du kannst neue Shortcuts erstellen, indem du eine Route planst und dann auf "Route speichern" klickst.',
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
            ),
            ShortcutsView(onSelectShortcut: onSelectShortcut, onStartFreeRouting: onStartFreeRouting),
            const VSpace(),
            const ProfileView(),
            const VSpace(),
            const SmallVSpace(),
            Divider(color: Theme.of(context).colorScheme.background, thickness: 2),
            const VSpace(),
            renderDebugHint(),
            const SizedBox(height: 128),
          ]),
        ),
      ],
    ));
  }
}