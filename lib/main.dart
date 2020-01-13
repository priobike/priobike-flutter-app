import 'package:bike_now_flutter/Services/appNavigationService.dart';
import 'package:bike_now_flutter/blocs/settings_bloc.dart';
import 'package:bike_now_flutter/helper/palette.dart';
import 'package:flutter/material.dart';

// own imports
import 'Services/router.dart';
import 'package:bike_now_flutter/websocket/web_socket_service.dart';

import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:bike_now_flutter/blocs/bloc_manager.dart';

import 'package:uuid/uuid.dart';

final RouteObserver<PageRoute> routeObserver = new RouteObserver<PageRoute>();

void main() {
  //Services
  WebSocketService webSocketService = WebSocketService.instance;
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  print(Uuid().v4());
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
        initialRoute: Router.initRoute,
        title: 'BikeNow',
        navigatorObservers: [routeObserver],
        navigatorKey: AppNavigationService.instance.navigatorKey,
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
            textTheme: TextTheme()),
      ),
    );
  }
}
