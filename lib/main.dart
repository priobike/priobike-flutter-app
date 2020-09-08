import 'package:bikenow/services/status_service.dart';
import 'package:bikenow/services/app_service.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'config/router.dart';

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
            brightness: Brightness.dark,
            fontFamily: "Roboto"
          )),
    );
  }
}
