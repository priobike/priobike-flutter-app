import 'package:bike_now_flutter/pages/home_page.dart';
import 'package:bike_now_flutter/pages/init_page.dart';
import 'package:bike_now_flutter/pages/navigation_page.dart';
import 'package:bike_now_flutter/pages/route_creation_page.dart';
import 'package:bike_now_flutter/pages/route_information_page.dart';
import 'package:bike_now_flutter/pages/settings_page.dart';
import 'package:bike_now_flutter/pages/summary_page.dart';
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
      case routeCreationRoute:
        return MaterialPageRoute(builder: (_) => RouteCreationPage());
      case routeInfoRoute:
        return MaterialPageRoute(builder: (_) => RouteInformationPage());
      case navigationRoute:
        return MaterialPageRoute(builder: (_) => NavigationPage());
      case settingsRoute:
        return MaterialPageRoute(builder: (_) => SettingsPage());
      case summaryRoute:
        return MaterialPageRoute(builder: (_) => SummaryPage());

      default:
        return MaterialPageRoute(
            builder: (_) => Scaffold(
                  body: Center(
                      child: Text('No route defined for ${settings.name}')),
                ));
    }
  }
}
