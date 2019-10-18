import 'package:bike_now_flutter/Services/appNavigationService.dart';
import 'package:bike_now_flutter/blocs/settings_bloc.dart';
import 'package:bike_now_flutter/helper/palette.dart';
import 'package:bike_now_flutter/pages/init_page.dart';
import 'package:bike_now_flutter/pages/onboarding_page.dart';
import 'package:bike_now_flutter/pages/route_creation_page.dart';
import 'package:bike_now_flutter/pages/settings_page.dart';
import 'package:bike_now_flutter/pages/summary_page.dart';
import 'package:flutter/material.dart';

// own imports
import 'Services/router.dart';
import 'pages/home_page.dart';
import 'package:bike_now_flutter/websocket/web_socket_service.dart';
import 'package:bike_now_flutter/pages/route_information_page.dart';
import 'package:bike_now_flutter/pages/navigation_page.dart';

import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:bike_now_flutter/blocs/bloc_manager.dart';

final RouteObserver<PageRoute> routeObserver = new RouteObserver<PageRoute>();

void main() {
  //Services
  WebSocketService webSocketService = WebSocketService.instance;
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ManagerBloc>.value(value: ManagerBloc()),
        ChangeNotifierProvider<SettingsBloc>.value(value: SettingsBloc()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: Router.homeRoute,
        title: 'BikeNow',
        navigatorObservers: [routeObserver],
        navigatorKey: AppNavigationService.instance.navigatorKey,
        onGenerateRoute: Router.generateRoute,
        theme: new ThemeData(
            primaryColor: Palette.primaryColor,
          scaffoldBackgroundColor: Palette.background,
          accentColor: Palette.primaryColor,
          backgroundColor: Palette.primaryDarkColor,


          appBarTheme: AppBarTheme(
            color: Palette.primaryColor
          ),
          primaryTextTheme: TextTheme(
            caption: TextStyle(color: Colors.white),
            body1: TextStyle(color: Colors.white),
            display1: TextStyle(color: Colors.white),

          )
        ),
      ),
    );
  }
}
