import 'dart:async';

import 'package:flutter/material.dart';
import 'package:priobike/feedback/services/feedback.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/main.dart';
import 'package:priobike/privacy/services.dart';
import 'package:priobike/privacy/views.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/ride/services/reroute.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/ride/services/session.dart';
import 'package:priobike/settings/service.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:provider/provider.dart';

void main() {
  final log = Logger("main.dart");

  // Display Flutter errors and log them to the logger.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    log.e(details.stack);
  };

  // Run the app, catch errors and dispatch them to the logger.
  runZonedGuarded(() => runApp(const App()), (Object error, StackTrace stack) {
    // Log the error to the console.
    log.e(error);
    log.e(stack);
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
      // All providers must reside above the MaterialApp.
      // Otherwise, they will get disposed when calling the Navigator.
      providers: [
        ChangeNotifierProvider<PrivacyPolicyService>(create: (context) => PrivacyPolicyService()),
        ChangeNotifierProvider<TutorialService>(create: (context) => TutorialService()),
        ChangeNotifierProvider<SettingsService>(create: (context) => SettingsService()),
        ChangeNotifierProvider<ProfileService>(create: (context) => ProfileService()),
        ChangeNotifierProvider<ShortcutsService>(create: (context) => ShortcutsService()),
        ChangeNotifierProvider<DiscomfortService>(create: (context) => DiscomfortService()),
        ChangeNotifierProvider<GeocodingService>(create: (context) => GeocodingService()),
        ChangeNotifierProvider<RoutingService>(create: (context) => RoutingService()),
        ChangeNotifierProvider<SessionService>(create: (context) => SessionService()),
        ChangeNotifierProvider<PositionService>(create: (context) => PositionService()),
        ChangeNotifierProvider<RideService>(create: (context) => RideService()),
        ChangeNotifierProvider<RerouteService>(create: (context) => RerouteService()),
        ChangeNotifierProvider<FeedbackService>(create: (context) => FeedbackService()),
      ],
      child: MaterialApp(
        title: 'PrioBike',
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            background: Color(0xF6F6F6FF),
            primary: Color.fromARGB(255, 0, 115, 255),
            secondary: Color.fromARGB(255, 0, 198, 255),
            surface: Color(0xFFFFFFFF),
          ),
        ),
        // The navigator key is used to access the app's build context.
        navigatorKey: navigatorKey,
        home: const PrivacyPolicyView(
          child: HomeView(),
        ),
      ),
    );
  }
}
