import 'package:bikenow/pages/home_page.dart';
import 'package:bikenow/pages/init_page.dart';
import 'package:bikenow/pages/navigation_page.dart';
import 'package:bikenow/pages/route_info_page.dart';
import 'package:bikenow/pages/summary_page.dart';
import 'package:flutter/material.dart';

class AppPage {
  static const String init = '/init';
  static const String routeCreation = '/routeCreation';
  static const String routeInfo = '/routeInfo';
  static const String navigation = '/navigation';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String summary = '/summary';

  static var all = {
    AppPage.init: (context) => InitPage(),
    AppPage.home: (context) => HomePage(),
    AppPage.routeInfo: (context) => RouteInfoPage(),
    AppPage.navigation: (context) => NavigationPage(),
    AppPage.summary: (context) => SummaryPage(),
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
