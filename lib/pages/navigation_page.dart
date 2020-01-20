import 'package:bikenow/services/app_router.dart';
import 'package:bikenow/services/main_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NavigationPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NavigationPageState();
  }
}

class _NavigationPageState extends State<NavigationPage> {
  @override
  Widget build(BuildContext context) {
    final app = Provider.of<MainService>(context);
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Text("navigation"),
            for (var item in app.predictions.values)
              Row(
                children: <Widget>[Text(item.sg), Text(item.timestamp)],
              ),
            RaisedButton(
              child: Text("beenden"),
              onPressed: () {
                app.unsubscribeFromRoute();
                Navigator.pushNamed(context, Router.summaryRoute);
              },
            ),
          ],
        ),
      ),
    );
  }
}
