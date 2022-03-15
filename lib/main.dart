import 'dart:async';

import 'package:flutter/material.dart';
import 'package:priobike/services/app.dart';
import 'package:priobike/services/settings.dart';
import 'package:priobike/utils/logger.dart';
import 'package:provider/provider.dart';
import 'package:priobike/utils/routes.dart';

void main() {
  Logger log = Logger("Main");

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    log.e(details.toString());
  };

  runZonedGuarded(() {
    runApp(const PrioBike());
  }, (Object error, StackTrace stack) {
    log.e(error.toString());
  });
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

  @override
  Widget build(BuildContext context) {
    settings = Provider.of<SettingsService>(context);

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
    );
  }
}
