import 'package:bikenow/pages/home_page.dart';
import 'package:bikenow/pages/init_page.dart';
import 'package:bikenow/pages/navigation_page.dart';
import 'package:bikenow/pages/route_info_page.dart';
import 'package:bikenow/pages/summary_page.dart';
import 'package:flutter/material.dart';

class Page {
  static const String init = '/init';
  static const String routeCreation = '/routeCreation';
  static const String routeInfo = '/routeInfo';
  static const String navigation = '/navigation';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String summary = '/summary';
}

class Routes {
  static var all = {
    Page.init: (context) => InitPage(),
    Page.home: (context) => HomePage(),
    Page.routeInfo: (context) => RouteInfoPage(),
    Page.navigation: (context) => NavigationPage(),
    Page.summary: (context) => SummaryPage(),
  };

  static onUnknownRoute(RouteSettings settings) {
    return new MaterialPageRoute(
      builder: (context) => Scaffold(
        body: Center(
          child: Text('Fehler: Keine Route festgelegt für "${settings.name}"'),
        ),
      ),
    );
  }
}
