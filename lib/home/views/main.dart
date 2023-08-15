import 'package:flutter/material.dart' hide Shortcuts, Feedback;
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/modal.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/hub/views/main.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/nav.dart';
import 'package:priobike/home/views/profile.dart';
import 'package:priobike/home/views/shortcuts/edit.dart';
import 'package:priobike/home/views/shortcuts/import.dart';
import 'package:priobike/home/views/shortcuts/invalid_shortcut_dialog.dart';
import 'package:priobike/home/views/shortcuts/selection.dart';
import 'package:priobike/home/views/survey.dart';
import 'package:priobike/main.dart';
import 'package:priobike/news/services/news.dart';
import 'package:priobike/news/views/main.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/settings/views/main.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/status/services/status_history.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/status/views/status_tabs.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:priobike/tutorial/view.dart';
import 'package:priobike/weather/service.dart';
import 'package:priobike/wiki/view.dart';

/// List that holds the number of app uses when the rate function should be triggered.
const List<int> askRateAppList = [5, 10, 20, 40, 60, 100, 150, 200, 300];

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

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

  /// The associated discomfort service, which is injected by the provider.
  late Discomforts discomforts;

  /// The associated sg status service, which is injected by the provider.
  late PredictionSGStatus predictionSGStatus;

  /// The associated prediction status service, which is injected by the provider.
  late PredictionStatusSummary predictionStatusSummary;

  /// The associated status history service, which is injected by the provider.
  late StatusHistory statusHistory;

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
    statusHistory = getIt<StatusHistory>();
    routing = getIt<Routing>();
    discomforts = getIt<Discomforts>();
    predictionSGStatus = getIt<PredictionSGStatus>();

    // Check if app should be rated.
    if (askRateAppList.contains(settings.useCounter)) {
      rateApp();
    }
  }

  /// Function that starts the inAppReview.
  Future<void> rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    }
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
      statusHistory.fetch();
      news.getArticles();
    }
  }

  @override
  void didPopNext() {
    predictionStatusSummary.fetch();
    statusHistory.fetch();
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
      final backend = getIt<Settings>().backend;
      final shortcuts = getIt<Shortcuts>();
      showDialog(
        context: context,
        builder: (context) => InvalidShortCutDialog(
          backend: backend,
          shortcuts: shortcuts,
          shortcut: shortcut,
          context: context,
        ),
      );
      return;
    }

    // Tell the tutorial service that the shortcut was selected.
    getIt<Tutorial>().complete("priobike.tutorial.select-shortcut");

    final waypoints = shortcut.getWaypoints();
    routing.selectWaypoints(waypoints);

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
          discomforts.reset();
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        edgeOffset: 128 + MediaQuery.of(context).padding.top,
        color: Colors.white,
        backgroundColor: Theme.of(context).colorScheme.primary,
        displacement: 42,
        onRefresh: () async {
          HapticFeedback.lightImpact();
          await predictionStatusSummary.fetch();
          await statusHistory.fetch();
          await news.getArticles();
          await getIt<Weather>().fetch();
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
                  if (settings.useCounter >= 3 && !settings.dismissedSurvey) const VSpace(),
                  if (settings.useCounter >= 3 && !settings.dismissedSurvey)
                    BlendIn(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const SurveyView(
                          dismissible: true,
                        ),
                      ),
                    ),
                  const VSpace(),
                  const BlendIn(
                    child: StatusTabsView(),
                  ),
                  const VSpace(),
                  BlendIn(
                    delay: const Duration(milliseconds: 250),
                    child: Row(
                      children: [
                        const SizedBox(width: 40),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BoldContent(text: "Deine Strecken & Orte", context: context),
                            const SizedBox(height: 4),
                            Small(text: "Direkt zum Ziel navigieren", context: context),
                          ],
                        ),
                        Expanded(child: Container()),
                        SmallIconButton(
                          onPressed: () => showAppSheet(
                            context: context,
                            builder: (context) => const ImportShortcutDialog(),
                          ),
                          icon: Icons.add_rounded,
                          fill: Theme.of(context).colorScheme.background,
                          splash: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        SmallIconButton(
                          icon: Icons.list_rounded,
                          fill: Theme.of(context).colorScheme.background,
                          splash: Colors.white,
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
                  if (settings.enableGamification)
                    Column(children: [
                      const VSpace(),
                      BlendIn(
                        delay: const Duration(milliseconds: 1000),
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const GameView())),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.background,
                              borderRadius: const BorderRadius.all(Radius.circular(24)),
                            ),
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                width: MediaQuery.of(context).size.width,
                                child: Row(
                                  children: [
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          BoldContent(text: "PrioBike Challenge", context: context),
                                          const SizedBox(height: 4),
                                          Small(text: "Dein aktueller Fortschritt", context: context),
                                        ],
                                      ),
                                    ),
                                  ],
                                )),
                          ),
                        ),
                      ),
                    ]),
                  const VSpace(),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.background,
                          Theme.of(context).colorScheme.background,
                          Theme.of(context).colorScheme.surface.withOpacity(0),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        const BlendIn(
                          delay: Duration(milliseconds: 1250),
                          child: WikiView(),
                        ),
                        const SizedBox(height: 32),
                        BoldSmall(
                          text: "radkultur hamburg",
                          context: context,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
