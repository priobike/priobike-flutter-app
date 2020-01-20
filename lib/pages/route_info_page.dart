import 'package:bikenow/services/main_service.dart';
import 'package:bikenow/services/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RouteInfoPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RouteInfoPageState();
  }
}

class _RouteInfoPageState extends State<RouteInfoPage> {
  @override
  Widget build(BuildContext context) {
    final app = Provider.of<MainService>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text("Streckenvorschau"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Text(
                'Distanz: ${((app.route.distance ?? 0) / 1000).toStringAsFixed(2)} Kilometer'),
            Text('${(app.route?.sg?.length ?? 0)} Ampeln'),
            Text(
                'Dauer: ${Duration(milliseconds: app.route?.time).inMinutes} Minuten'),
            Text('Anstieg: ${(app.route?.ascend ?? 0)} Meter'),
            Text('Gefälle: ${(app.route?.descend ?? 0)} Meter'),
            IconButton(
                icon: Icon(Icons.directions_bike),
                tooltip: 'Routing Starten',
                onPressed: () {
                  app.subscribeToRoute();
                  Navigator.pushReplacementNamed(
                      context, Router.navigationRoute);
                }),
            Text('Routing Starten'),
          ],
        ),
      ),
    );
  }
}
