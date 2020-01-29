import 'package:bikenow/services/gateway_status_service.dart';
import 'package:bikenow/services/main_service.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'services/app_router.dart';

import 'package:logging/logging.dart';

import 'config/palette.dart';

void main() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MainService>(
            create: (context) => MainService()),
        ChangeNotifierProvider<GatewayStatusService>(
            create: (context) => GatewayStatusService()),
      ],
      child: MaterialApp(
        initialRoute: Router.initRoute,
        title: 'BikeNow',
        onGenerateRoute: Router.generateRoute,
        theme: new ThemeData(
          primaryColor: Palette.primaryColor,
          scaffoldBackgroundColor: Palette.background,
          accentColor: Palette.primaryColor,
          backgroundColor: Palette.primaryDarkColor,
          hintColor: Colors.white,
          appBarTheme: AppBarTheme(
            color: Palette.primaryColor,
          ),
          primaryTextTheme: TextTheme(
            caption: TextStyle(color: Colors.white),
            body1: TextStyle(color: Colors.white),
            display1: TextStyle(color: Colors.white),
          ),
          textTheme: TextTheme(),
        ),
      ),
    );
  }
}
