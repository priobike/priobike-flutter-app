import 'package:bikenow/services/status_service.dart';
import 'package:bikenow/services/app_service.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'config/router.dart';

import 'config/palette.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppService>(create: (context) => AppService()),
        ChangeNotifierProvider<StatusService>(
            create: (context) => StatusService()),
      ],
      child: MaterialApp(
        title: 'BikeNow',
        initialRoute: AppPage.init,
        routes: AppPage.all,
        onUnknownRoute: (settings) => AppPage.noRoute(settings),
        theme: new ThemeData(
          primaryColor: Palette.primaryColor,
          scaffoldBackgroundColor: Palette.background,
          accentColor: Palette.primaryColor,
          backgroundColor: Palette.primaryDarkColor,
          hintColor: Colors.white,
          appBarTheme: AppBarTheme(
            color: Palette.primaryColor,
          ),
        ),
      ),
    );
  }
}
