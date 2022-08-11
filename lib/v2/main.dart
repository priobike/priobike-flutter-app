

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:priobike/v2/common/logger.dart';
import 'package:priobike/v2/home/services/profile.dart';
import 'package:priobike/v2/home/services/shortcuts.dart';
import 'package:priobike/v2/home/views/main.dart';
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
    return MaterialApp(
      title: 'PrioBike',
      theme: ThemeData(
        colorSchemeSeed: Colors.white,
        useMaterial3: true,
      ),
      // The navigator key is used to access the app's build context.
      navigatorKey: navigatorKey,
      home: Scaffold(body: MultiProvider(
        providers: [
          ChangeNotifierProvider<ShortcutsService>(
            create: (context) => ShortcutsService(),
          ),
          ChangeNotifierProvider<ProfileService>(
            create: (context) => ProfileService(),
          ),
        ],
        child: const HomeView(),
      )),
    );
  }
}
