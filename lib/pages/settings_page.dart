import 'package:priobike/config/priobike_theme.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SettingsPageState();
  }
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: PrioBikeTheme.background,
        appBar: AppBar(
          title: Text("Einstellungen"),
          elevation: PrioBikeTheme.buttonElevation,
          backgroundColor: PrioBikeTheme.background,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Settings',
            style: TextStyle(
              color: PrioBikeTheme.text,
            ),
          ),
        ),
      ),
    );
  }
}
