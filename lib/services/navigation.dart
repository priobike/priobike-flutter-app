import 'package:flutter/material.dart';

/// A global navigation service to access the app's build context.
class NavigationService { 
  /// The current navigator state key of the app.
  static GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}