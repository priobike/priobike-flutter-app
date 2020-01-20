import 'package:bikenow/services/app_router.dart';
import 'package:flutter/material.dart';

class NavigationPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NavigationPageState();
  }
}

class _NavigationPageState extends State<NavigationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Text("navigation"),
            RaisedButton(
              child: Text("beenden"),
              onPressed: () => Navigator.pushNamed(context, Router.summaryRoute),
            )
          ],
        ),
      ),
    );
  }
}
