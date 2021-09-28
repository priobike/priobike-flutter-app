import 'package:priobike/pages/cycling.dart';
import 'package:priobike/pages/home.dart';
import 'package:priobike/pages/log.dart';
import 'package:priobike/pages/route.dart';
import 'package:priobike/pages/settings.dart';
import 'package:priobike/pages/start.dart';
import 'package:flutter/material.dart';
import 'package:priobike/pages/summary.dart';

class Routes {
  static const String start = '/start';
  static const String route = '/route';
  static const String cycling = '/cycling';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String summary = '/summary';
  static const String log = '/log';

  static var all = {
    Routes.start: (context) => const StartPage(),
    Routes.home: (context) => const HomePage(),
    Routes.cycling: (context) => const CyclingPage(),
    Routes.settings: (context) => const SettingsPage(),
    Routes.summary: (context) => const SummaryPage(),
    Routes.log: (context) => const LogPage(),
    Routes.route: (contex) => const RoutePage(),
  };

  static noRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        body: Center(
          child: Text('Fehler: Keine Route festgelegt für "${settings.name}"'),
        ),
      ),
    );
  }
}
