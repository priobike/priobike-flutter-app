import 'package:flutter/material.dart';

class AppNavigationService {
  final GlobalKey<NavigatorState> navigatorKey =
      new GlobalKey<NavigatorState>();

  AppNavigationService._privateConstructor();
  static final AppNavigationService instance =
      AppNavigationService._privateConstructor();

  Future<dynamic> navigateTo(String routeName) {
    return navigatorKey.currentState.pushNamed(routeName);
  }
}
