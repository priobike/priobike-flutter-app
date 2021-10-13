import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:priobike/services/settings.dart';
import 'package:priobike/utils/routes.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SettingsPageState();
  }
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsService settings;

  @override
  Widget build(BuildContext context) {
    settings = Provider.of<SettingsService>(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Einstellungen'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              ElevatedButton(
                child: const Text('Logs ansehen'),
                onPressed: () {
                  Navigator.pushNamed(context, Routes.log);
                },
              ),
              ElevatedButton.icon(
                icon: Icon(
                  settings.getThemeMode() == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                label: Text(
                  settings.getThemeMode() == ThemeMode.dark
                      ? 'Light Mode'
                      : 'Dark Mode',
                ),
                onPressed: () {
                  settings.getThemeMode() == ThemeMode.dark
                      ? settings.setThemeMode(ThemeMode.light)
                      : settings.setThemeMode(ThemeMode.dark);
                },
              ),
              ElevatedButton(
                child: const Text('Zurück'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        ),
      ),
    );
  }
}
