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
  MainService app;

  @override
  Widget build(BuildContext context) {
    app = Provider.of<MainService>(context);
    return SafeArea(
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(8),
          children: <Widget>[
            Card(
              child: ListTile(
                title: Text('Fahrt beenden'),
                onTap: () {
                  Navigator.pushReplacementNamed(context, Router.summaryRoute);
                },
              ),
            ),
            for (var item in app.predictions.values)
              Card(
                child: ListTile(
                  title: Text(item.lsa + ': ' + item.sg),
                  subtitle: Text(item.timestamp + ' ' + item.value),
                  trailing: CircularProgressIndicator(
                    value: 0.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    app.unsubscribeFromRoute();
  }
}
