import 'package:priobike/pages/choose_route_page.dart';
import 'package:priobike/pages/log_page.dart';
import 'package:priobike/pages/main_page.dart';
import 'package:priobike/pages/navigation_page.dart';
import 'package:priobike/pages/route_info_page.dart';
import 'package:priobike/pages/settings_page.dart';
import 'package:priobike/pages/start_page.dart';
import 'package:priobike/pages/summary_page.dart';
import 'package:flutter/material.dart';

class AppPage {
  static const String init = '/init';
  static const String chooseRoute = '/chooseRoute';
  static const String routeInfo = '/routeInfo';
  static const String navigation = '/navigation';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String summary = '/summary';
  static const String log = '/log';

  static var all = {
    AppPage.init: (context) => StartPage(),
    AppPage.home: (context) => MainPage(),
    AppPage.routeInfo: (context) => RouteInfoPage(),
    AppPage.navigation: (context) => NavigationPage(),
    AppPage.settings: (context) => SettingsPage(),
    AppPage.summary: (context) => SummaryPage(),
    AppPage.log: (context) => LogPage(),
    AppPage.chooseRoute: (contex) => ChooseRoutePage(),
  };

  static noRoute(RouteSettings settings) {
    return new MaterialPageRoute(
      builder: (context) => Scaffold(
        body: Center(
          child: Text('Fehler: Keine Route festgelegt für "${settings.name}"'),
        ),
      ),
    );
  }
}
