import 'package:flutter/material.dart';

/// A view that shows all the licenses from packages used in the app.
class LicenseView extends StatelessWidget {
  /// The app name.
  final String? appName;

  /// The app version of the app.
  final String? appVersion;

  const LicenseView({
    this.appName,
    this.appVersion,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: AppBarTheme(
          elevation: 0,
          titleTextStyle: const TextStyle(fontSize: 20, color: Colors.black),
          toolbarTextStyle: const TextStyle(fontSize: 20, color: Colors.black),
          color: Theme.of(context).colorScheme.background,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        cardColor: Theme.of(context).colorScheme.background,
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.black),
          titleSmall: TextStyle(color: Colors.black),
          titleMedium: TextStyle(color: Colors.black),
          headlineSmall: TextStyle(color: Colors.black),
          headlineMedium: TextStyle(color: Colors.black),
          headlineLarge: TextStyle(color: Colors.black),
          bodyLarge: TextStyle(color: Colors.black),
          bodySmall: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          labelLarge: TextStyle(color: Colors.black),
          labelSmall: TextStyle(color: Colors.black),
          labelMedium: TextStyle(color: Colors.black),
        ),
      ),
      child: LicensePage(
        applicationName: appName,
        applicationVersion: appVersion,
        applicationIcon: const Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Image(
            image: AssetImage('assets/icon.png'),
            height: 25,
          ),
        ),
      ),
    );
  }
}
