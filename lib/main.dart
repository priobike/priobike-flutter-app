import 'dart:async';

import 'package:flutter/material.dart' hide Feedback, Shortcuts;
import 'package:get_it/get_it.dart';
import 'package:priobike/common/fcm.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/map/map_design.dart';
import 'package:priobike/feedback/services/feedback.dart';
import 'package:priobike/gamification/challenges/services/challenges_profile_service.dart';
import 'package:priobike/gamification/challenges/services/challenge_service.dart';
import 'package:priobike/gamification/goals/services/user_goals_service.dart';
import 'package:priobike/gamification/statistics/services/statistics_service.dart';
import 'package:priobike/home/services/poi.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/loader.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/news/services/news.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/privacy/services.dart';
import 'package:priobike/privacy/views.dart';
import 'package:priobike/ride/services/datastream.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/color_mode.dart';
import 'package:priobike/settings/services/features.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/status/services/status_history.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/traffic/services/traffic_service.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:priobike/weather/service.dart';

final log = Logger("main.dart");

final RouteObserver<ModalRoute<dynamic>> routeObserver = RouteObserver<ModalRoute<dynamic>>();

/// The central getIt instance that is used to access the singleton services.
final getIt = GetIt.instance;

Future<void> main() async {
  // Ensure that the widgets binding is initialized.
  // This is required by some plugins and functions.
  WidgetsFlutterBinding.ensureInitialized();

  // The feature service needs to load first, as it sets the backend which is used by other services.
  getIt.registerSingleton<Feature>(Feature());
  final feature = getIt<Feature>();
  await feature.load();
  getIt.registerSingleton<Settings>(Settings(feature.defaultBackend));
  final settings = getIt<Settings>();
  await settings.loadSettings(feature.canEnableInternalFeatures, feature.canEnableBetaFeatures);

  // Setup the push notifications. We cannot do this in the
  // widget tree down further, as a restriction of Android.
  await FCM.load(settings.backend);

  // Register the services.
  getIt.registerSingleton<Weather>(Weather());
  getIt.registerSingleton<PrivacyPolicy>(PrivacyPolicy());
  getIt.registerSingleton<Tutorial>(Tutorial());
  getIt.registerSingleton<PredictionStatusSummary>(PredictionStatusSummary());
  getIt.registerSingleton<PredictionSGStatus>(PredictionSGStatus());
  getIt.registerSingleton<Profile>(Profile());
  getIt.registerSingleton<News>(News());
  getIt.registerSingleton<Shortcuts>(Shortcuts());
  getIt.registerSingleton<Discomforts>(Discomforts());
  getIt.registerSingleton<Geocoding>(Geocoding());
  getIt.registerSingleton<Geosearch>(Geosearch());
  getIt.registerSingleton<Routing>(Routing());
  getIt.registerSingleton<Layers>(Layers());
  getIt.registerSingleton<MapDesigns>(MapDesigns());
  getIt.registerSingleton<Positioning>(Positioning());
  getIt.registerSingleton<Datastream>(Datastream());
  getIt.registerSingleton<Tracking>(Tracking());
  getIt.registerSingleton<Statistics>(Statistics());
  getIt.registerSingleton<Feedback>(Feedback());
  getIt.registerSingleton<Ride>(Ride());
  getIt.registerSingleton<Traffic>(Traffic());
  getIt.registerSingleton<Boundary>(Boundary());
  getIt.registerSingleton<StatusHistory>(StatusHistory());
  getIt.registerSingleton<GamificationUserService>(GamificationUserService());
  getIt.registerSingleton<POI>(POI());
  getIt.registerSingleton<StatisticService>(StatisticService());
  getIt.registerSingleton<DailyChallengeService>(DailyChallengeService());
  getIt.registerSingleton<WeeklyChallengeService>(WeeklyChallengeService());
  getIt.registerSingleton<UserGoalsService>(UserGoalsService());
  getIt.registerSingleton<ChallengesProfileService>(ChallengesProfileService());

  runZonedGuarded(() async {
    runApp(const App());
  }, (error, stack) async {
    // Log the error to the console.
    log.e(error.toString());
    log.e(stack.toString());
  });
}

/// The main app widget.
class App extends StatelessWidget {
  /// The current navigator state key of the app.
  static final navigatorKey = GlobalKey<NavigatorState>();

  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        final settings = GetIt.instance.get<Settings>();
        settings.addListener(() => setState(() {}));

        return MaterialApp(
          title: 'PrioBike',
          showPerformanceOverlay: settings.enablePerformanceOverlay,
          navigatorObservers: [routeObserver],
          theme: ThemeData(
            dialogBackgroundColor: const Color(0xFFFFFFFF),
            fontFamily: 'HamburgSans',
            colorScheme: const ColorScheme.light(
              background: Color(0xFFFFFFFF),
              primary: CI.blue,
              secondary: CI.blueLight,
              surface: Color(0xFFF6F6FF),
              brightness: Brightness.light,
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 38,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
              displayMedium: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
              displaySmall: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: Color(0xFF000000),
              ),
              headlineMedium: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
              bodyLarge: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: Color(0xFF000000),
              ),
              titleMedium: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: Color(0xFF000000),
              ),
              titleSmall: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            dialogBackgroundColor: const Color(0xFF232323),
            fontFamily: 'HamburgSans',
            colorScheme: const ColorScheme.dark(
              background: Color.fromARGB(255, 31, 31, 31),
              primary: CI.blue,
              secondary: CI.blueLight,
              surface: Color.fromARGB(255, 42, 42, 42),
              surfaceTint: Color.fromARGB(255, 42, 42, 42),
              brightness: Brightness.dark,
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 38,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
              ),
              displayMedium: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
              ),
              displaySmall: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: Color(0xFFFFFFFF),
              ),
              headlineMedium: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
              ),
              bodyLarge: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: Color(0xFFFFFFFF),
              ),
              titleMedium: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: Color(0xFFFFFFFF),
              ),
              titleSmall: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
              ),
            ),
            useMaterial3: true,
          ),
          themeMode: settings.colorMode == ColorMode.light
              ? ThemeMode.light
              : settings.colorMode == ColorMode.dark
                  ? ThemeMode.dark
                  // Fallback to the system preference.
                  : ThemeMode.system,
          // The navigator key is used to access the app's build context.
          navigatorKey: navigatorKey,
          home: const PrivacyPolicyView(child: Loader()),
        );
      },
    );
  }
}
