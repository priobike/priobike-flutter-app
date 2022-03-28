import 'dart:async';

import 'package:flutter/material.dart';
import 'package:priobike/services/app.dart';
import 'package:priobike/services/settings.dart';
import 'package:priobike/utils/logger.dart';
import 'package:priobike/utils/routes.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'services/navigation.dart';

void main() {
  Logger log = Logger("Main");

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    log.e(details.toString());
  };

  // Initialize Sentry.
  SentryFlutter.init(
    (options) {
      options.dsn =
          'https://9414569965e1478cbe58f12a3a4cb39e@priobike.vkw.tu-dresden.de/2';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
      // It is recommended adjusting this value in production.
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runZonedGuarded(() {
      runApp(const PrioBike());
    }, (Object error, StackTrace stack) {
      // Log the error to the console.
      log.e(error.toString());

      // Dispatch the error to Sentry, if it is available.
      try {
        Sentry.captureException(error, stackTrace: stack);
      } catch (e) {
        log.e("Sentry is unavailable: $e");
      }
    }),
  );
}

class PrioBike extends StatelessWidget {
  const PrioBike({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppService>(
          create: (context) => AppService(),
        ),
        ChangeNotifierProvider<SettingsService>(
          create: (context) => SettingsService(),
        ),
      ],
      child: const Main(),
    );
  }
}

class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  late SettingsService settings;
  late AppService appService;

  @override
  Widget build(BuildContext context) {
    settings = Provider.of<SettingsService>(context);
    appService = Provider.of<AppService>(context);

    return MaterialApp(
      title: 'PrioBike',
      initialRoute: Routes.start,
      routes: Routes.all,
      onUnknownRoute: (settings) => Routes.noRoute(settings),
      theme: ThemeData(
        colorSchemeSeed: Colors.blue[900],
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue[900],
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: settings.getThemeMode(),
      navigatorKey: NavigationService.key,
    );
  }
}
