import 'package:flutter/material.dart';
import 'package:priobike/services/app.dart';
import 'package:priobike/services/settings.dart';
import 'package:provider/provider.dart';
import 'package:priobike/utils/routes.dart';

void main() => runApp(const PrioBike());

class PrioBike extends StatelessWidget {
  const PrioBike({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppService>(
          create: (context) => AppService(),
        ),
        ChangeNotifierProvider<SettingsService>(
          create: (context) => SettingsService(),
        ),
      ],
      child: const Main(),
    );
  }
}

class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  late SettingsService settings;

  @override
  Widget build(BuildContext context) {
    settings = Provider.of<SettingsService>(context);

    return MaterialApp(
      title: 'PrioBike',
      initialRoute: Routes.start,
      routes: Routes.all,
      onUnknownRoute: (settings) => Routes.noRoute(settings),
      theme: ThemeData(primarySwatch: Colors.green),
      darkTheme: ThemeData.dark(),
      themeMode: settings.getThemeMode(),
    );
  }
}
