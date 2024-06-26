import 'dart:async';

import 'package:flutter/material.dart' hide Feedback, Shortcuts;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Feature, Settings;
import 'package:priobike/common/fcm.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/map/map_design.dart';
import 'package:priobike/feedback/services/feedback.dart';
import 'package:priobike/home/services/load.dart';
import 'package:priobike/home/services/poi.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/http.dart';
import 'package:priobike/loader.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/migration/user_transfer_view.dart';
import 'package:priobike/news/services/news.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/privacy/services.dart';
import 'package:priobike/privacy/views.dart';
import 'package:priobike/ride/services/datastream.dart';
import 'package:priobike/ride/services/free_ride.dart';
import 'package:priobike/ride/services/live_tracking.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/ride/services/speedsensor.dart';
import 'package:priobike/routing/services/boundary.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/routing/services/poi.dart';
import 'package:priobike/routing/services/profile.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/settings/models/color_mode.dart';
import 'package:priobike/settings/services/features.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/simulator/services/simulator.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:priobike/status/services/sg.dart';
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
  // Enable this to show the layout bounds.
  debugPaintSizeEnabled = false;

  // Slow down animations with timeDilation > 1.0.
  timeDilation = 1.0;

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

  // Setup the logger.
  await Logger.init(settings.enableLogPersistence);

  // Setup the push notifications. We cannot do this in the
  // widget tree down further, as a restriction of Android.
  await FCM.load(settings.backend);

  // Init the HTTP client for all services.
  Http.initClient();

  // Register the services.
  getIt.registerSingleton<Weather>(Weather());
  getIt.registerSingleton<PrivacyPolicy>(PrivacyPolicy());
  getIt.registerSingleton<Tutorial>(Tutorial());
  getIt.registerSingleton<PredictionStatusSummary>(PredictionStatusSummary());
  getIt.registerSingleton<PredictionSGStatus>(PredictionSGStatus());
  getIt.registerSingleton<Profile>(Profile());
  getIt.registerSingleton<News>(News());
  getIt.registerSingleton<Shortcuts>(Shortcuts());
  getIt.registerSingleton<Pois>(Pois());
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
  getIt.registerSingleton<FreeRide>(FreeRide());
  getIt.registerSingleton<Traffic>(Traffic());
  getIt.registerSingleton<Boundary>(Boundary());
  getIt.registerSingleton<POI>(POI());
  getIt.registerSingleton<Simulator>(Simulator());
  getIt.registerSingleton<LiveTracking>(LiveTracking());
  getIt.registerSingleton<SpeedSensor>(SpeedSensor());
  getIt.registerSingleton<LoadStatus>(LoadStatus());
  getIt.registerSingleton<Toast>(Toast());
  try {
    runApp(const App());
  } on Error catch (error, stack) {
    // Log the error to the console.
    log.e("Error during app startup: $error");
    log.e(stack);
  }
}

/// The main app widget.
class App extends StatelessWidget {
  /// The current navigator state key of the app.
  static final navigatorKey = GlobalKey<NavigatorState>();

  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        final settings = GetIt.instance.get<Settings>();
        settings.addListener(() => setState(() {}));

        return MaterialApp(
          title: 'PrioBike',
          showPerformanceOverlay: settings.enablePerformanceOverlay,
          builder: (context, child) => ToastWrapper(
            child: child ?? const SizedBox(),
          ),
          onGenerateRoute: (routeSettings) {
            String? url = routeSettings.name!;

            // Check if url is a short or long link.
            if (!url.contains("/link/") && !url.contains("/import/")) url = null;

            // Required to make sure that home view doesn't get opened twice if the user clicks on an
            // import link while the app is already open in the background.
            navigatorKey.currentState?.popUntil((route) => false);

            return MaterialPageRoute(
              builder: (context) => PrivacyPolicyView(
                child: UserTransferView(
                  child: Loader(shareUrl: url),
                ),
              ),
            );
          },
          // The navigator key is used to access the app's build context.
          navigatorKey: navigatorKey,
          navigatorObservers: [routeObserver],
          theme: ThemeData(
            dialogBackgroundColor: const Color(0xFFFFFFFF),
            scaffoldBackgroundColor: const Color(0xFFFCFCFC),
            fontFamily: 'HamburgSans',
            colorScheme: const ColorScheme.light(
              primary: CI.radkulturRed,
              onPrimary: Colors.white,
              secondary: CI.radkulturRedDark,
              onSecondary: Color(0xFFCCCCCC),
              tertiary: Color(0xFF444444),
              onTertiary: Color(0xFFDDDDDD),
              // For the background of complete views/pages.
              surface: Color(0xFFFCFCFC),
              // For content on the background (color with high contrast).
              onSurface: Color(0xFF000000),
              // Neutral alternative for surface.
              surfaceVariant: Color(0xFFFFFFFF),
              // For content on the alternative surface (color with high contrast).
              onSurfaceVariant: Color(0xFF000000),
              // For the splash effect on buttons.
              surfaceTint: Color(0x6BFFFFFF),
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
              headlineLarge: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
              headlineMedium: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
              headlineSmall: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: Color(0xFF000000),
              ),
              bodyLarge: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: Color(0xFF000000),
              ),
              bodyMedium: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Color(0xFF000000),
              ),
              bodySmall: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: Color(0xFF000000),
              ),
              titleLarge: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 24,
                fontWeight: FontWeight.w600,
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
            scaffoldBackgroundColor: const Color(0xFF222222),
            fontFamily: 'HamburgSans',
            colorScheme: const ColorScheme.dark(
              primary: CI.radkulturRed,
              onPrimary: Colors.white,
              secondary: CI.radkulturRedDark,
              onSecondary: Color(0xFFCCCCCC),
              tertiary: Color(0xFFDDDDDD),
              onTertiary: Color(0xFF333333),
              // For the background of complete views/pages.
              surface: Color(0xFF222222),
              // For content on the background (color with high contrast).
              onSurface: Color(0xFFFFFFFF),
              // Neutral alternative for surface.
              surfaceVariant: Color(0xFF131313),
              // For content on the alternative surface (color with high contrast).
              onSurfaceVariant: Color(0xFFFFFFFF),
              // For the splash effect on buttons.
              surfaceTint: Color(0x6B232323),
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
              ),
              headlineLarge: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
              ),
              headlineMedium: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
              ),
              headlineSmall: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: Color(0xFFFFFFFF),
              ),
              bodyLarge: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: Color(0xFFFFFFFF),
              ),
              bodyMedium: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Color(0xFFFFFFFF),
              ),
              bodySmall: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: Color(0xFFFFFFFF),
              ),
              titleLarge: TextStyle(
                fontFamily: 'HamburgSans',
                fontSize: 24,
                fontWeight: FontWeight.w600,
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
        );
      },
    );
  }
}
