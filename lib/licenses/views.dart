import 'package:flutter/cupertino.dart';
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.black),
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
        applicationLegalese: "applicationLegalese - TODO",
      ),
    );
  }
}
