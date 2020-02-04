import 'package:bikenow/services/gateway_status_service.dart';
import 'package:bikenow/services/main_service.dart';
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
        ChangeNotifierProvider<MainService>(create: (context) => MainService()),
        ChangeNotifierProvider<GatewayStatusService>(
            create: (context) => GatewayStatusService()),
      ],
      child: MaterialApp(
        title: 'BikeNow',
        initialRoute: Page.init,
        routes: Page.all,
        onUnknownRoute: (settings) => Page.noRoute(settings),
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
