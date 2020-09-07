import 'package:bikenow/config/router.dart';
import 'package:bikenow/models/recommendation.dart';
import 'package:bikenow/services/app_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NavigationPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NavigationPageState();
  }
}

class _NavigationPageState extends State<NavigationPage> {
  AppService app;

  @override
  void didChangeDependencies() {
    app = Provider.of<AppService>(context);
    // app.geolocationService.startGeolocation();
    // app.predictionService.subscribeToRoute();
    // app.recommendationService.startRecommendation();
    // app.trackingService.startTracking();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: <Widget>[
            Expanded(child: Text("todo")),
            Card(
              child: ListTile(
                title: Text('Fahrt beenden'),
                onTap: () {
                  Navigator.pushReplacementNamed(context, AppPage.summary);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // app.predictionService.unsubscribeFromRoute();
    // app.recommendationService.endRecommendation();
    // app.geolocationService.stopGeolocation();
    // app.trackingService.stopTracking();
    super.dispose();
  }
}
