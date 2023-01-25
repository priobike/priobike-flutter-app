import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/places.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/nav.dart';
import 'package:priobike/home/views/profile.dart';
import 'package:priobike/routing/routing_view_wrapper.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/status/views/status.dart';
import 'package:priobike/news/services/news.dart';
import 'package:priobike/news/views/main.dart';
import 'package:priobike/home/views/shortcuts/edit.dart';
import 'package:priobike/home/views/shortcuts/selection.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/settings/views/main.dart';
import 'package:priobike/statistics/views/total.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:priobike/tutorial/view.dart';
import 'package:priobike/weather/service.dart';
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

  /// The associated shortcuts service, which is injected by the provider.
  late Places places;

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
    places = Provider.of<Places>(context);
    routing = Provider.of<Routing>(context, listen: false);
    discomforts = Provider.of<Discomforts>(context, listen: false);
    predictionSGStatus = Provider.of<PredictionSGStatus>(context, listen: false);
    statistics = Provider.of<Statistics>(context, listen: false);

    super.didChangeDependencies();
  }

  /// A callback that is fired when the notification button is tapped.
  void onNotificationsButtonTapped() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewsView())).then(
      (_) {
        // Mark all notifications as read.
        news.markAllArticlesAsRead(context);
      },
    );
  }

  /// A callback that is fired when the settings button is tapped.
  void onSettingsButtonTapped() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsView(),
      ),
    );
  }

  /// A callback that is fired when a shortcut was selected.
  void onSelectShortcut(Shortcut shortcut) {
    // Tell the tutorial service that the shortcut was selected.
    Provider.of<Tutorial>(context, listen: false).complete("priobike.tutorial.select-shortcut");

    routing.selectWaypoints(shortcut.waypoints);

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RoutingViewWrapper()))
        .then(
      (_) {
        routing.reset();
        discomforts.reset();
        predictionSGStatus.reset();
      },
    );
  }

  /// A callback that is fired when free routing was selected.
  void onStartFreeRouting() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RoutingViewWrapper()))
        .then(
      (_) {
        routing.reset();
        discomforts.reset();
        predictionSGStatus.reset();
      },
    );
  }

  /// A callback that is fired when the shortcuts should be edited.
  void onOpenShortcutEditView() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShortcutsEditView()));
  }

  Widget renderDebugHint() {
    String? description;
    if (settings.backend != Backend.production) {
      description = "Testort ist gewählt.";
    }
    if (settings.positioningMode != PositioningMode.gnss) {
      description = "Testortung ist aktiv.";
    }
    if (description == null) return Container();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: Color.fromARGB(246, 230, 51, 40),
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: HPad(
          child: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white),
              const SmallHSpace(),
              Flexible(child: Content(text: description, context: context, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        edgeOffset: 128 + MediaQuery.of(context).padding.top,
        color: Colors.white,
        backgroundColor: Theme.of(context).colorScheme.primary,
        displacement: 42,
        onRefresh: () async {
          HapticFeedback.lightImpact();
          await Provider.of<PredictionStatusSummary>(context, listen: false).fetch(context);
          await Provider.of<Weather>(context, listen: false).fetch(context);
          // Wait for one more second, otherwise the user will get impatient.
          await Future.delayed(
            const Duration(seconds: 1),
          );
          HapticFeedback.lightImpact();
        },
        child: CustomScrollView(
          slivers: <Widget>[
            NavBarView(
              onTapNotificationButton: onNotificationsButtonTapped,
              onTapSettingsButton: onSettingsButtonTapped,
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const VSpace(),
                  const BlendIn(child: StatusView()),
                  BlendIn(
                    delay: const Duration(milliseconds: 250),
                    child: Row(
                      children: [
                        const SizedBox(width: 40),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BoldContent(text: "Deine Strecken", context: context),
                            const SizedBox(height: 4),
                            Small(text: "Direkt zum Ziel navigieren", context: context),
                          ],
                        ),
                        Expanded(child: Container()),
                        SmallIconButton(
                          icon: Icons.edit_rounded,
                          fill: Theme.of(context).colorScheme.background,
                          splash: Colors.white,
                          onPressed: onOpenShortcutEditView,
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  const VSpace(),
                  BlendIn(
                    delay: const Duration(milliseconds: 500),
                    child: Column(
                      children: [
                        const TutorialView(
                          id: "priobike.tutorial.select-shortcut",
                          text:
                              'Fährst du eine Route häufiger? Du kannst neue Strecken erstellen, indem du eine Route planst und dann auf "Strecke speichern" klickst.',
                          padding: EdgeInsets.fromLTRB(40, 0, 40, 24),
                        ),
                        ShortcutsView(onSelectShortcut: onSelectShortcut, onStartFreeRouting: onStartFreeRouting)
                      ],
                    ),
                  ),
                  const BlendIn(
                    delay: Duration(milliseconds: 750),
                    child: ProfileView(),
                  ),
                  const VSpace(),
                  const SmallVSpace(),
                  const BlendIn(
                    delay: Duration(milliseconds: 1000),
                    child: TotalStatisticsView(),
                  ),
                  const VSpace(),
                  BlendIn(
                    delay: const Duration(milliseconds: 1250),
                    child: renderDebugHint(),
                  ),
                  const SizedBox(height: 128),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
