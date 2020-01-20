import 'package:bikenow/pages/home_page.dart';
import 'package:bikenow/pages/init_page.dart';
import 'package:bikenow/pages/navigation_page.dart';
import 'package:bikenow/pages/route_info_page.dart';
import 'package:bikenow/pages/summary_page.dart';
import 'package:flutter/material.dart';

class Router {
  static const String initRoute = '/init';
  static const String onboardingRoute = '/onboarding';
  static const String routeCreationRoute = '/routeCreation';
  static const String routeInfoRoute = '/routeInfo';
  static const String navigationRoute = '/navigation';
  static const String homeRoute = '/';
  static const String settingsRoute = '/settings';
  static const String summaryRoute = '/summary';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initRoute:
        return MaterialPageRoute(builder: (_) => InitPage());
      case homeRoute:
        return MaterialPageRoute(builder: (_) => HomePage());
      case routeInfoRoute:
        return MaterialPageRoute(builder: (_) => RouteInfoPage());
      case navigationRoute:
        return MaterialPageRoute(builder: (_) => NavigationPage());
      case summaryRoute:
        return MaterialPageRoute(builder: (_) => SummaryPage());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child:
                  Text('Fehler: Keine Route festgelegt für "${settings.name}"'),
            ),
          ),
        );
    }
  }
}
