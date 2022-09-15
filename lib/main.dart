import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/feedback/services/feedback.dart';
import 'package:priobike/home/services/status.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/main.dart';
import 'package:priobike/news/service.dart';
import 'package:priobike/privacy/services.dart';
import 'package:priobike/privacy/views.dart';
import 'package:priobike/positioning/services/estimator.dart';
import 'package:priobike/positioning/services/position.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/positioning/services/snapping.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/ride/services/session.dart';
import 'package:priobike/routingNew/services/mapcontroller.dart';
import 'package:priobike/settings/models/color_mode.dart';
import 'package:priobike/settings/services/features.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/settings/views/features.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// For older Android devices (Android 5), there will sometimes be a 
/// HTTP error due to an expired certificate. This certificate lies within 
/// the Android operating system and is not part of the app. For our app 
/// to work on older Android devices, we need to ignore the certificate error. 
/// Note that this is a workaround and should be handled with care.
/// See: https://github.com/flutter/flutter/issues/19588#issuecomment-406779390
class OldAndroidHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super
      .createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  HttpOverrides.global = OldAndroidHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  /// ColorMode has to be loaded before first build method
  SharedPreferences storage = await SharedPreferences.getInstance();
  ColorMode colorMode = ColorMode.system;
  final colorModeStr = storage.getString("priobike.settings.colorMode");
  if (colorModeStr != null) colorMode = ColorMode.values.byName(colorModeStr);

  final log = Logger("main.dart");

  // Display Flutter errors and log them to the logger.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    log.e(details.stack);
  };

  // Run the app, catch errors and dispatch them to the logger.
  runZonedGuarded(() => runApp(App(colorMode: colorMode)), (Object error, StackTrace stack) {
    // Log the error to the console.
    log.e(error);
    log.e(stack);
  });
}

/// The main app widget.
class App extends StatelessWidget {
  /// The current navigator state key of the app.
  static final navigatorKey = GlobalKey<NavigatorState>();
  final ColorMode colorMode;

  const App({Key? key, required this.colorMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // All providers must reside above the MaterialApp.
      // Otherwise, they will get disposed when calling the Navigator.
      providers: [
        ChangeNotifierProvider<FeatureService>(create: (context) => FeatureService()),
        ChangeNotifierProvider<PrivacyPolicyService>(create: (context) => PrivacyPolicyService()),
        ChangeNotifierProvider<TutorialService>(create: (context) => TutorialService()),
        ChangeNotifierProvider<SettingsService>(create: (context) => SettingsService(colorMode: colorMode)),
        ChangeNotifierProvider<PredictionStatusService>(create: (context) => PredictionStatusService()),
        ChangeNotifierProvider<ProfileService>(create: (context) => ProfileService()),
        ChangeNotifierProvider<NewsService>(create: (context) => NewsService()),
        ChangeNotifierProvider<ShortcutsService>(create: (context) => ShortcutsService()),
        ChangeNotifierProvider<DiscomfortService>(create: (context) => DiscomfortService()),
        ChangeNotifierProvider<GeocodingService>(create: (context) => GeocodingService()),
        ChangeNotifierProvider<GeosearchService>(create: (context) => GeosearchService()),
        ChangeNotifierProvider<RoutingService>(create: (context) => RoutingService()),
        ChangeNotifierProvider<SessionService>(create: (context) => SessionService()),
        ChangeNotifierProvider<PositionService>(create: (context) => PositionService()),
        ChangeNotifierProvider<PositionEstimatorService>(create: (context) => PositionEstimatorService()),
        ChangeNotifierProvider<RideService>(create: (context) => RideService()),
        ChangeNotifierProvider<StatisticsService>(create: (context) => StatisticsService()),
        ChangeNotifierProvider<SnappingService>(create: (context) => SnappingService()),
        ChangeNotifierProvider<FeedbackService>(create: (context) => FeedbackService()),
        ChangeNotifierProvider<MapControllerService>(create: (context) => MapControllerService()),
      ],
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          SettingsService settingsService =
              Provider.of<SettingsService>(context);
          ColorMode colorMode = settingsService.colorMode;

          return MaterialApp(
            title: 'PrioBike',
            theme: ThemeData(
              colorScheme: const ColorScheme.light(
                  background: Color(0xFFFFFFFF),
                  primary: Color.fromARGB(255, 0, 115, 255),
                  secondary: Color.fromARGB(255, 0, 198, 255),
                  surface: Color(0xF6F6F6FF),
                  brightness: Brightness.light),
              textTheme: const TextTheme(
                  headline1: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000)),
                  headline2: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000)),
                  headline3: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF000000)),
                  headline4: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000)),
                  bodyText1: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF000000)),
                  subtitle1: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF000000)),
                  subtitle2: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000))),
            ),
            darkTheme: ThemeData(
              colorScheme: const ColorScheme.dark(
                  background: Color(0xFF232323),
                  primary: Color.fromARGB(255, 0, 115, 255),
                  secondary: Color.fromARGB(255, 0, 198, 255),
                  surface: Color(0xF63B3B3B),
                  brightness: Brightness.dark),
              textTheme: const TextTheme(
                  headline1: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFFFF)),
                  headline2: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFFFF)),
                  headline3: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFFFFFFFF)),
                  headline4: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFFFF)),
                  bodyText1: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFFFFFFFF)),
                  subtitle1: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFFFFFFFF)),
                  subtitle2: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFFFF))),
            ),
            themeMode: colorMode == ColorMode.light
                ? ThemeMode.light
                : colorMode == ColorMode.dark
                    ? ThemeMode.dark
                    : ThemeMode.system,
            // The navigator key is used to access the app's build context.
            navigatorKey: navigatorKey,
            home: const FeatureLoaderView(
              child: PrivacyPolicyView(
                child: HomeView(),
              ),
            ),
          );
        },
      ),
    );
  }
}
