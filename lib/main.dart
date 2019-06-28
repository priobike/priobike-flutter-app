import 'package:flutter/material.dart';

// own imports
import 'pages/home_page.dart';
import 'package:bike_now/websocket/web_socket_service.dart';
import 'package:bike_now/pages/route_information_page.dart';
import 'package:bike_now/pages/navigation_page.dart';

import 'package:logging/logging.dart';

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
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/second': (context) => RouteInformationPage(),
        '/navigation': (context) => NavigationPage(),
      },
      title: 'My Flutter App',
      theme: new ThemeData(
          primaryColor: Colors.blue
      ),
    );
  }
}

