import 'dart:async';

import 'package:flutter/material.dart';
import 'package:priobike/common/logger.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/home/views/main.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/ride/services/recommendation/recommendation.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/session/services/session.dart';
import 'package:priobike/settings/service.dart';
import 'package:provider/provider.dart';

void main() {
  final log = Logger("main.dart");

  // Display Flutter errors and log them to the logger.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    log.e(details.toString());
  };

  // Run the app, catch errors and dispatch them to the logger.
  runZonedGuarded(() => runApp(const App()), (Object error, StackTrace stack) {
    // Log the error to the console.
    log.e(error.toString());
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
        ChangeNotifierProvider<SettingsService>(create: (context) => SettingsService()),
        ChangeNotifierProvider<ProfileService>(create: (context) => ProfileService()),
        ChangeNotifierProvider<ShortcutsService>(create: (context) => ShortcutsService()),
        ChangeNotifierProvider<RoutingService>(create: (context) => RoutingService()),
        ChangeNotifierProvider<SessionService>(create: (context) => SessionService()),
        ChangeNotifierProvider<PositionService>(create: (context) => PositionService()),
        ChangeNotifierProvider<RecommendationService>(create: (context) => RecommendationService()),
      ],
      child: MaterialApp(
        title: 'PrioBike',
        theme: ThemeData(
          colorSchemeSeed: Colors.white,
          useMaterial3: true,
        ),
        // The navigator key is used to access the app's build context.
        navigatorKey: navigatorKey,
        home: const Scaffold(body: HomeView()),
      ),
    );
  }
}
