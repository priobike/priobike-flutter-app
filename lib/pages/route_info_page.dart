import 'package:bikenow/services/routing_service.dart';
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
    final route = Provider.of<RoutingService>(context);
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
                'Distanz: ${((route.answer.distance ?? 0) / 1000).toStringAsFixed(2)} Kilometer'),
            Text('${(route.answer?.sg?.length ?? 0)} Ampeln'),
            Text(
                'Dauer: ${Duration(milliseconds: route.answer?.time).inMinutes} Minuten'),
            Text('Anstieg: ${(route.answer?.ascend ?? 0)} Meter'),
            Text('Gefälle: ${(route.answer?.descend ?? 0)} Meter'),
            IconButton(
              icon: Icon(Icons.directions_bike),
              tooltip: 'Routing Starten',
              onPressed: () => Navigator.pushReplacementNamed(
                  context, Router.navigationRoute),
            ),
            Text('Routing Starten')
          ],
        ),
      ),
    );
  }
}
