import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Feedback, Shortcuts;
import 'package:priobike/accelerometer/services/accelerometer.dart';
import 'package:priobike/common/fcm.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/dangers/services/dangers.dart';
import 'package:priobike/feedback/services/feedback.dart';
import 'package:priobike/home/services/places.dart';
import 'package:priobike/routing/services/bottom_sheet_state.dart';
import 'package:priobike/loader.dart';
import 'package:priobike/news/services/news.dart';
import 'package:priobike/ride/services/datastream.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/privacy/services.dart';
import 'package:priobike/privacy/views.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/services/map_settings.dart';
import 'package:priobike/settings/models/color_mode.dart';
import 'package:priobike/settings/services/features.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/statistics/services/statistics.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:priobike/weather/service.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final log = Logger("main.dart");

Future<void> main() async {
  // Ensure that the widgets binding is initialized.
  // This is required by some plugins and functions.
  WidgetsFlutterBinding.ensureInitialized();

  // Setup the push notifications. We cannot do this in the
  // widget tree down further, as a restriction of Android.
  await FCM.load(await Settings.loadBackendFromSharedPreferences());

  runZonedGuarded(() async {
    runApp(const App());
  }, (error, stack) async {
    // Log the error to the console.
    log.e(error.toString());
    log.e(stack.toString());
    // Send the error to Sentry, but only if we are not in debug mode.
    if (!kDebugMode) await Sentry.captureException(error, stackTrace: stack);
  });
}

/// The main app widget.
class App extends StatelessWidget {
  /// The current navigator state key of the app.
  static final navigatorKey = GlobalKey<NavigatorState>();

  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // All changenotifiers reside above the MaterialApp, as of now.
      // This is to make sure that changenotifiers are not disposed when
      // calling the navigator. In this way, it is always safe to use
      // Provider.of(...) in any build context. However, it needs to be
      // ensured that the changenotifiers are properly recycled.
      // For this, changenotifiers may provide a `reset` method.
      providers: [
        ChangeNotifierProvider(create: (context) => Feature()),
        ChangeNotifierProvider(create: (context) => PrivacyPolicy()),
        ChangeNotifierProvider(create: (context) => Tutorial()),
        ChangeNotifierProvider(create: (context) => Settings()),
        ChangeNotifierProvider(create: (context) => PredictionStatusSummary()),
        ChangeNotifierProvider(create: (context) => PredictionSGStatus()),
        ChangeNotifierProvider(create: (context) => Profile()),
        ChangeNotifierProvider(create: (context) => News()),
        ChangeNotifierProvider(create: (context) => Shortcuts()),
        ChangeNotifierProvider(create: (context) => Places()),
        ChangeNotifierProvider(create: (context) => Discomforts()),
        ChangeNotifierProvider(create: (context) => Geocoding()),
        ChangeNotifierProvider(create: (context) => Geosearch()),
        ChangeNotifierProvider(create: (context) => Routing()),
        ChangeNotifierProvider(create: (context) => Layers()),
        ChangeNotifierProvider(create: (context) => Positioning()),
        ChangeNotifierProvider(create: (context) => Accelerometer()),
        ChangeNotifierProvider(create: (context) => Dangers()),
        ChangeNotifierProvider(create: (context) => Datastream()),
        ChangeNotifierProvider(create: (context) => Tracking()),
        ChangeNotifierProvider(create: (context) => Statistics()),
        ChangeNotifierProvider(create: (context) => Feedback()),
        ChangeNotifierProvider(create: (context) => MapSettings()),
        ChangeNotifierProvider(create: (context) => BottomSheetState()),
        ChangeNotifierProvider(create: (context) => Weather()),
        ChangeNotifierProvider(create: (context) => Ride()),
      ],
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          final settings = Provider.of<Settings>(context);

          return MaterialApp(
            title: 'PrioBike',
            showPerformanceOverlay: settings.enablePerformanceOverlay,
            theme: ThemeData(
              dialogBackgroundColor: const Color(0xFFFFFFFF),
              fontFamily: 'HamburgSans',
              colorScheme: const ColorScheme.light(
                background: Color(0xFFFFFFFF),
                primary: CI.blue,
                secondary: CI.lightBlue,
                surface: Color(0xFFF6F6FF),
                brightness: Brightness.light,
              ),
              textTheme: const TextTheme(
                headline1: TextStyle(
                  fontFamily: 'HamburgSans',
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
                headline2: TextStyle(
                  fontFamily: 'HamburgSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
                headline3: TextStyle(
                  fontFamily: 'HamburgSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF000000),
                ),
                headline4: TextStyle(
                  fontFamily: 'HamburgSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
                bodyText1: TextStyle(
                  fontFamily: 'HamburgSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF000000),
                ),
                subtitle1: TextStyle(
                  fontFamily: 'HamburgSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF000000),
                ),
                subtitle2: TextStyle(
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
                background: Color(0xFF232323),
                primary: CI.blue,
                secondary: CI.lightBlue,
                surface: Color(0xFF3B3B3B),
                brightness: Brightness.dark,
              ),
              textTheme: const TextTheme(
                headline1: TextStyle(
                  fontFamily: 'HamburgSans',
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                ),
                headline2: TextStyle(
                  fontFamily: 'HamburgSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                ),
                headline3: TextStyle(
                  fontFamily: 'HamburgSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFFFFFFFF),
                ),
                headline4: TextStyle(
                  fontFamily: 'HamburgSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                ),
                bodyText1: TextStyle(
                  fontFamily: 'HamburgSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFFFFFFFF),
                ),
                subtitle1: TextStyle(
                  fontFamily: 'HamburgSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFFFFFFFF),
                ),
                subtitle2: TextStyle(
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
      ),
    );
  }
}
