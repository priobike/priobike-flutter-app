import 'package:flutter/material.dart' hide Shortcuts, Feedback;
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/release.dart';
import 'package:priobike/home/views/load_status.dart';
import 'package:priobike/home/views/nav.dart';
import 'package:priobike/home/views/poi/your_bike.dart';
import 'package:priobike/home/views/restart_route_dialog.dart';
import 'package:priobike/home/views/shortcuts/edit.dart';
import 'package:priobike/home/views/shortcuts/import.dart';
import 'package:priobike/home/views/shortcuts/selection.dart';
import 'package:priobike/main.dart';
import 'package:priobike/news/services/news.dart';
import 'package:priobike/news/views/main.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/profile.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/settings/views/main.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/status/views/status.dart';
import 'package:priobike/tracking/views/track_history.dart';
import 'package:priobike/tutorial/view.dart';
import 'package:priobike/weather/service.dart';
import 'package:priobike/wiki/view.dart';

class HomeView extends StatefulWidget {
  /// The shortcut loaded by a share link.
  final Shortcut? shortcut;

  const HomeView({super.key, this.shortcut});

  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> with WidgetsBindingObserver, RouteAware {
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

  /// The associated ride service, which is injected by the provider.
  late Ride ride;

  /// The associated sg status service, which is injected by the provider.
  late PredictionSGStatus predictionSGStatus;

  /// The associated prediction status service, which is injected by the provider.
  late PredictionStatusSummary predictionStatusSummary;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    news = getIt<News>();
    news.addListener(update);
    profile = getIt<Profile>();
    profile.addListener(update);
    settings = getIt<Settings>();
    settings.addListener(update);
    shortcuts = getIt<Shortcuts>();
    shortcuts.addListener(update);
    predictionStatusSummary = getIt<PredictionStatusSummary>();
    routing = getIt<Routing>();
    routing.addListener(update);
    ride = getIt<Ride>();
    predictionSGStatus = getIt<PredictionSGStatus>();

    /// List that holds the number of app uses when the rate function should be triggered.
    const List<int> askRateAppList = [5, 20, 40, 60, 100, 150, 200, 300];
    if (askRateAppList.contains(settings.useCounter)) rateApp();

    // Check if the last route finished accordingly.
    if (ride.lastRoute != null) {
      // Copy waypoints.
      List<Waypoint> lastRoute = ride.lastRoute!;
      // Remove last route entry.
      ride.removeLastRoute();
      // Open restart route dialog.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          // Execute callback if page is mounted
          if (mounted) {
            showRestartRouteDialog(context, ride.lastRouteID, lastRoute);
          }
        },
      );
    }

    // Check if a shortcut from a share link should be imported.
    if (widget.shortcut != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          // Execute callback if page is mounted
          if (mounted) {
            showSaveShortcutFromShortcutSheet(context, shortcut: widget.shortcut!);
          }
        },
      );
    }
  }

  /// Function that starts the inAppReview.
  Future<void> rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;
    if (!await inAppReview.isAvailable()) return;

    inAppReview.requestReview();
    // increment use counter to avoid asking again when we recreate the home view.
    settings.incrementUseCounter();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      predictionStatusSummary.fetch();
      news.getArticles();
    }
  }

  @override
  void didPopNext() {
    predictionStatusSummary.fetch();
    news.getArticles();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    news.removeListener(update);
    profile.removeListener(update);
    settings.removeListener(update);
    shortcuts.removeListener(update);
    routing.removeListener(update);
    super.dispose();
  }

  /// A callback that is fired when the notification button is tapped.
  void onNotificationsButtonTapped() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewsView())).then(
      (_) {
        // Mark all notifications as read.
        news.markAllArticlesAsRead();
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
  /// Checks if the shortcut is valid, i.e. if all waypoints are inside the bounding box.
  Future<void> onSelectShortcut(Shortcut shortcut) async {
    HapticFeedback.mediumImpact();
    final shortcutIsValid = shortcut.isValid();

    if (!shortcutIsValid) {
      showInvalidShortcutSheet(context);
      return;
    }

    // Create new Shortcut copy to avoid changing the original Shortcut.
    final Shortcut newShortcut;
    if (shortcut is ShortcutLocation) {
      newShortcut = ShortcutLocation(
        id: shortcut.id,
        name: shortcut.name,
        waypoint: shortcut.waypoint,
      );
    } else if (shortcut is ShortcutRoute) {
      newShortcut = ShortcutRoute(
        id: shortcut.id,
        name: shortcut.name,
        waypoints: List<Waypoint>.from(shortcut.waypoints),
      );
    } else {
      throw UnimplementedError();
    }

    routing.selectWaypoints(newShortcut.getWaypoints());

    pushRoutingView();
  }

  /// A callback that is fired when free routing was selected.
  void onStartFreeRouting() {
    HapticFeedback.mediumImpact();

    pushRoutingView();
  }

  /// Pushes the routing view.
  /// Also handles the reset of services if the user navigates back to the home view after the routing view instead of starting a ride.
  /// If the routing view is popped after the user navigates to the ride view do not reset the services, because they are being used in the ride view.
  void pushRoutingView() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoutingView())).then(
      (comingNotFromRoutingView) {
        if (comingNotFromRoutingView == null) {
          routing.reset();
          predictionSGStatus.reset();
        }
      },
    );
  }

  /// A callback that is fired when the shortcuts should be edited.
  void onOpenShortcutEditView() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShortcutsEditView()));
  }

  @override
  Widget build(BuildContext context) {
    final showStatusView = predictionStatusSummary.getProblem() != null;

    return Scaffold(
      body: Stack(children: [
        RefreshIndicator(
          edgeOffset: 128 + MediaQuery.of(context).padding.top,
          color: Colors.white,
          backgroundColor: Theme.of(context).colorScheme.primary,
          displacement: 42,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            await predictionStatusSummary.fetch();
            await news.getArticles();
            await getIt<Weather>().fetch();
            // Wait for one more second, otherwise the user will get impatient.
            await Future.delayed(
              const Duration(seconds: 1),
            );
            HapticFeedback.lightImpact();
          },
          child: AnnotatedRegionWrapper(
            bottomBackgroundColor: Theme.of(context).colorScheme.surface,
            colorMode: Theme.of(context).brightness,
            child: CustomScrollView(
              slivers: <Widget>[
                NavBarView(
                  onTapNotificationButton: onNotificationsButtonTapped,
                  onTapSettingsButton: onSettingsButtonTapped,
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const LoadStatusView(),
                      const ReleaseInfoView(),
                      const VSpace(),
                      if (showStatusView)
                        const BlendIn(
                          child: Row(
                            children: [
                              SizedBox(width: 20),
                              Expanded(
                                child: StatusView(showPercentage: false),
                              ),
                              SizedBox(width: 20),
                            ],
                          ),
                        ),
                      if (showStatusView) const VSpace(),
                      BlendIn(
                        delay: const Duration(milliseconds: 250),
                        child: Row(
                          children: [
                            const SizedBox(width: 40),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  BoldSubHeader(
                                    text: "Navigation",
                                    context: context,
                                  ),
                                  const SizedBox(height: 4),
                                  Content(
                                    text: "Deine Strecken und Orte",
                                    context: context,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            SmallIconButtonPrimary(
                              onPressed: () => showAppSheet(
                                context: context,
                                builder: (context) => const ImportShortcutDialog(),
                              ),
                              icon: Icons.add_rounded,
                              splash: Theme.of(context).colorScheme.surfaceTint,
                            ),
                            const SizedBox(width: 8),
                            SmallIconButtonPrimary(
                              icon: Icons.list_rounded,
                              splash: Theme.of(context).colorScheme.surfaceTint,
                              onPressed: onOpenShortcutEditView,
                            ),
                            const SizedBox(width: 24),
                          ],
                        ),
                      ),
                      const VSpace(),
                      BlendIn(
                        delay: const Duration(milliseconds: 500),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 20),
                              child: TutorialView(
                                id: "priobike.tutorial.select-shortcut",
                                text:
                                    'Fährst Du eine Route häufiger? Du kannst neue Strecken erstellen, indem Du eine Route planst und dann auf "Strecke speichern" klickst.',
                                padding: EdgeInsets.fromLTRB(25, 0, 25, 24),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 20),
                              child: TutorialView(
                                id: "priobike.tutorial.share-shortcut",
                                text:
                                    'Fährst Du eine Route besonders gern und möchtest sie mit deinen Freunden teilen? Du kannst deine Strecke per Link oder QR Code teilen. Drücke dafür lang auf deine gespeicherte Strecke.',
                                padding: EdgeInsets.fromLTRB(25, 0, 25, 24),
                              ),
                            ),
                            ShortcutsView(onSelectShortcut: onSelectShortcut, onStartFreeRouting: onStartFreeRouting)
                          ],
                        ),
                      ),
                      const BlendIn(
                        delay: Duration(milliseconds: 750),
                        child: YourBikeView(),
                      ),
                      BlendIn(
                        delay: const Duration(milliseconds: 1000),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Divider(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1)),
                        ),
                      ),
                      const SmallVSpace(),
                      const TrackHistoryView(),
                      BlendIn(
                        delay: const Duration(milliseconds: 1000),
                        child: Container(
                          alignment: Alignment.topLeft,
                          padding: const EdgeInsets.only(left: 40, right: 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BoldSubHeader(
                                text: "Wie funktioniert PrioBike?",
                                context: context,
                                textAlign: TextAlign.center,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 4),
                              Content(
                                text: "Erfahre mehr über die App.",
                                context: context,
                                textAlign: TextAlign.center,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const VSpace(),
                      const BlendIn(
                        delay: Duration(milliseconds: 1250),
                        child: WikiView(),
                      ),
                      const VSpace(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        routing.isFetchingRoute
            ? Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(),
                  ),
                  const SmallVSpace(),
                  Content(text: "Route wird berechnet...", context: context),
                ]),
              )
            : const SizedBox(),
      ]),
    );
  }
}
