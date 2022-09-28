import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/nav.dart';
import 'package:priobike/home/views/profile.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/status/views/status.dart';
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
import 'package:priobike/statistics/views/total.dart';
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
  late News news;

  /// The associated profile service, which is injected by the provider.
  late Profile profile;

  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts shortcuts;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated discomfort service, which is injected by the provider.
  late Discomforts discomforts;

  /// The associated sg status service, which is injected by the provider.
  late PredictionSGStatus predictionSGStatus;

  /// The associated statistics service, which is injected by the provider.
  late Statistics statistics;

  @override
  void didChangeDependencies() {
    news = Provider.of<News>(context);
    profile = Provider.of<Profile>(context);
    settings = Provider.of<Settings>(context);
    shortcuts = Provider.of<Shortcuts>(context);

    routing = Provider.of<Routing>(context, listen: false);
    discomforts = Provider.of<Discomforts>(context, listen: false);
    predictionSGStatus = Provider.of<PredictionSGStatus>(context, listen: false);
    statistics = Provider.of<Statistics>(context, listen: false);

    // Load once the window was built.
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await news.getArticles(context);
      await settings.loadSettings();
      await profile.loadProfile();
      await shortcuts.loadShortcuts(context);
      await statistics.loadStatistics();
    });

    super.didChangeDependencies();
  }

  /// A callback that is fired when the notification button is tapped.
  void onNotificationsButtonTapped() {
    Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const NewsView()))
      .then((_) {
        // Mark all notifications as read.
        news.markAllArticlesAsRead(context);
      });
  }

  /// A callback that is fired when the settings button is tapped.
  void onSettingsButtonTapped() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsView()));
  }

  /// A callback that is fired when a shortcut was selected.
  void onSelectShortcut(Shortcut shortcut) {
    // Tell the tutorial service that the shortcut was selected.
    Provider.of<Tutorial>(context, listen: false).complete("priobike.tutorial.select-shortcut");

    routing.selectWaypoints(shortcut.waypoints);
    routing.loadRoutes(context);

    Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const RoutingView()))
      .then((_) {
        routing.reset();
        discomforts.reset();
        predictionSGStatus.reset();
      });
  }

  /// A callback that is fired when free routing was selected.
  void onStartFreeRouting() {
    Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const RoutingView()))
      .then((_) {
        routing.reset();
        discomforts.reset();
        predictionSGStatus.reset();
      });
  }

  /// A callback that is fired when the shortcuts should be edited.
  void onOpenShortcutEditView() {
    Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ShortcutsEditView()));
  }

  Widget renderDebugHint() {
    String? description;
    if (settings.backend != Backend.production) description = "Testort ist gewählt.";
    if (settings.positioningMode != PositioningMode.gnss) description = "Testortung ist aktiv.";
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
            const StatusView(),
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
            const TotalStatisticsView(),
            renderDebugHint(),
            const SizedBox(height: 128),
          ]),
        ),
      ],
    ));
  }
}