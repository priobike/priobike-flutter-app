import 'package:bikenow/config/bikenow_theme.dart';
import 'package:bikenow/config/router.dart';
import 'package:bikenow/services/app_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

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

    if (!app.isGeolocating) {
      app.startGeolocation();
    }

    Wakelock.enable();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = TextStyle(
      color: BikeNowTheme.text,
      fontSize: 20,
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: BikeNowTheme.background,
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: app.recommendation != null
              ? Column(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              "${app.recommendation.label}",
                              style: textStyle,
                            ),
                            Text(
                              "Countdown: ${app.recommendation.countdown}s",
                              style: TextStyle(
                                color: BikeNowTheme.text,
                                fontSize: 48,
                              ),
                            ),
                            Text(
                              "Distanz: ${app.recommendation.distance.toStringAsFixed(0)}m",
                              style: textStyle,
                            ),
                            Text(
                              "isGreen: ${app.recommendation.isGreen}",
                              style: textStyle,
                            ),
                            Text(
                              "SpeedRec: ${app.recommendation.speedRec}",
                              style: textStyle,
                            ),
                            Text(
                              "SpeedDiff: ${app.recommendation.speedDiff}",
                              style: textStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: RaisedButton.icon(
                        padding: EdgeInsets.all(12),
                        icon: Icon(
                          Icons.stop,
                        ),
                        label: Text("Fahrt beenden"),
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                              context, AppPage.home, (_) => false);
                          //Navigator.pushReplacementNamed(context, AppPage.summary); // TODO: enable summary page
                        },
                        elevation: BikeNowTheme.buttonElevation,
                        color: BikeNowTheme.button,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    "Warte auf Position...",
                    style: TextStyle(color: BikeNowTheme.text),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    app.stopGeolocation();
    Wakelock.disable();
    super.dispose();
  }
}
