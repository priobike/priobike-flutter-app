import 'package:flutter/material.dart';

// own imports
import 'pages/home_page.dart';

void main() {
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
      },
      title: 'My Flutter App',
      theme: new ThemeData(
          primaryColor: Colors.blue
      ),
    );
  }
}

