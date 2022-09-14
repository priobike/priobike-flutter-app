import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart' hide Feedback, Shortcuts;
import 'package:priobike/feedback/services/feedback.dart';
import 'package:priobike/status/services/status.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/main.dart';
import 'package:priobike/news/service.dart';
import 'package:priobike/privacy/services.dart';
import 'package:priobike/privacy/views.dart';
import 'package:priobike/positioning/services/estimator.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/positioning/services/snapping.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/ride/services/session.dart';
import 'package:priobike/settings/models/color_mode.dart';
import 'package:priobike/settings/services/features.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/settings/views/features.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:provider/provider.dart';

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

  // Ensure that the widgets binding is initialized before 
  // loading something from the shared preferences.
  WidgetsFlutterBinding.ensureInitialized();
  // Load the color mode before the first view build.
  final initialColorMode = await Settings.loadColorModeFromSharedPreferences();

  final log = Logger("main.dart");

  // Display Flutter errors and log them to the logger.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    log.e(details.stack);
  };

  // Run the app, catch errors and dispatch them to the logger.
  runZonedGuarded(
    () => runApp(App(initialColorMode: initialColorMode)), 
    (error, stack) {
      // Log the error to the console.
      log.e(error);
      log.e(stack);
    }
  );
}

/// The main app widget.
class App extends StatelessWidget {
  /// The current navigator state key of the app.
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// The color mode that is initially used by the app.
  final ColorMode initialColorMode;

  const App({required this.initialColorMode, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // All changenotifiers reside above the MaterialApp, as of now.
      // This is to make sure that changenotifiers are not disposed when 
      // calling the navigator. In this way, it is always safe to use 
      // Provider.of(...) in any build context. However, it needs to be 
      // ensured that the changenotifiers are properly recycled.
      // For this, changenotifiers may provider a `reset` method.
      providers: [
        ChangeNotifierProvider<Feature>(create: (context) => Feature()),
        ChangeNotifierProvider<PrivacyPolicy>(create: (context) => PrivacyPolicy()),
        ChangeNotifierProvider<Tutorial>(create: (context) => Tutorial()),
        ChangeNotifierProvider<Settings>(create: (context) => Settings(colorMode: initialColorMode)),
        ChangeNotifierProvider<PredictionStatus>(create: (context) => PredictionStatus()),
        ChangeNotifierProvider<Profile>(create: (context) => Profile()),
        ChangeNotifierProvider<News>(create: (context) => News()),
        ChangeNotifierProvider<Shortcuts>(create: (context) => Shortcuts()),
        ChangeNotifierProvider<Discomforts>(create: (context) => Discomforts()),
        ChangeNotifierProvider<Geocoding>(create: (context) => Geocoding()),
        ChangeNotifierProvider<Geosearch>(create: (context) => Geosearch()),
        ChangeNotifierProvider<Routing>(create: (context) => Routing()),
        ChangeNotifierProvider<Session>(create: (context) => Session()),
        ChangeNotifierProvider<Positioning>(create: (context) => Positioning()),
        ChangeNotifierProvider<PositionEstimator>(create: (context) => PositionEstimator()),
        ChangeNotifierProvider<Ride>(create: (context) => Ride()),
        ChangeNotifierProvider<Statistics>(create: (context) => Statistics()),
        ChangeNotifierProvider<Snapping>(create: (context) => Snapping()),
        ChangeNotifierProvider<Feedback>(create: (context) => Feedback()),
      ],
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          // Rebuild the view hierarchy when the color mode changes.
          final colorMode = Provider.of<Settings>(context).colorMode;

          return MaterialApp(
            title: 'PrioBike',
            theme: ThemeData(
              colorScheme: const ColorScheme.light(
                background: Color(0xFFFFFFFF),
                primary: Color.fromARGB(255, 0, 115, 255),
                secondary: Color.fromARGB(255, 0, 198, 255),
                surface: Color(0xF6F6F6FF),
                brightness: Brightness.light,
              ),
              textTheme: const TextTheme(
                headline1: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
                headline2: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
                headline3: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF000000),
                ),
                headline4: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
                bodyText1: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF000000)
                ),
                subtitle1: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF000000),
                ),
                subtitle2: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: const ColorScheme.dark(
                background: Color(0xFF232323),
                primary: Color.fromARGB(255, 0, 115, 255),
                secondary: Color.fromARGB(255, 0, 198, 255),
                surface: Color(0xF63B3B3B),
                brightness: Brightness.dark,
              ),
              textTheme: const TextTheme(
                headline1: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                ),
                headline2: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                ),
                headline3: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFFFFFFFF),
                ),
                headline4: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                ),
                bodyText1: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFFFFFFFF),
                ),
                subtitle1: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFFFFFFFF),
                ),
                subtitle2: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            themeMode: colorMode == ColorMode.light
              ? ThemeMode.light
              : colorMode == ColorMode.dark
                ? ThemeMode.dark
                // Fallback to the system preference.
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
