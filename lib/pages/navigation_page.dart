import 'package:priobike/config/priobike_theme.dart';
import 'package:priobike/config/logger.dart';
import 'package:priobike/config/router.dart';
import 'package:priobike/services/app_service.dart';
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
  Logger log = Logger("NavigationPage");
  AppService app;

  var _pageController = PageController(
    initialPage: 0,
  );

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
      color: PrioBikeTheme.text,
      fontSize: 20,
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: PrioBikeTheme.background,
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: app.recommendation != null
              ? Column(
                  children: <Widget>[
                    Expanded(
                      child: PageView(
                        onPageChanged: (value) {
                          // setState(() {
                          //   _currentIndex = value;
                          // });
                        },
                        controller: _pageController,
                        children: [
                          Container(
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
                                    color: PrioBikeTheme.text,
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
                                Text(
                                  "error: ${app.recommendation.error}",
                                  style: textStyle,
                                ),
                                Text(
                                  "message: ${app.recommendation.errorMessage}",
                                  style: textStyle,
                                ),
                              ],
                            ),
                          ),
                          Container(
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
                                  "${app.recommendation.countdown}s",
                                  style: TextStyle(
                                    color: PrioBikeTheme.text,
                                    fontSize: 72,
                                  ),
                                ),
                                Text(
                                  "Distanz: ${app.recommendation.distance.toStringAsFixed(0)}m",
                                  style: textStyle,
                                ),
                              ],
                            ),
                          ),
                        ],
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
                        onPressed: () async {
                          await app.stopGeolocation();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppPage.home,
                            (_) => false,
                          );
                          //Navigator.pushReplacementNamed(context, AppPage.summary); // TODO: enable summary page
                        },
                        elevation: PrioBikeTheme.buttonElevation,
                        color: PrioBikeTheme.button,
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
                    "Warte auf Server...",
                    style: TextStyle(
                      color: PrioBikeTheme.text,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    log.i("NavigationPage disposed.");
    if (app.isGeolocating) app.stopGeolocation();
    Wakelock.disable();
    super.dispose();
  }
}
