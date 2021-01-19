import 'package:bikenow/config/bikenow_theme.dart';
import 'package:bikenow/config/router.dart';
import 'package:bikenow/services/app_service.dart';
import 'package:bikenow/services/status_service.dart';
import 'package:bikenow/widgets/destination_button.dart';
import 'package:bikenow/widgets/route_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OverviewPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _OverviewPageState();
  }
}

class _OverviewPageState extends State<OverviewPage> {
  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppService>(context);
    final statusService = Provider.of<StatusService>(context);
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: RaisedButton.icon(
                    padding: EdgeInsets.all(16),
                    icon: Icon(
                      Icons.location_on,
                    ),
                    label: Text(
                      "Zu Ziel navigieren",
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, AppPage.chooseRoute);
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
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: RaisedButton.icon(
                    padding: EdgeInsets.all(16),
                    icon: Icon(Icons.directions_bike),
                    label: Text(
                      "Freie Fahrt",
                      textAlign: TextAlign.start,
                    ),
                    onPressed: () {},
                    elevation: BikeNowTheme.buttonElevation,
                    color: BikeNowTheme.button,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                child: Text(
                  "Letzte Ziele",
                  style: TextStyle(fontSize: 23, color: Colors.white60),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                      child: DestinationButton(
                        destination: "Zuhause",
                        onPressed: () async {
                          // await app.updateRoute(0, 0, 1, 1);
                          // Navigator.pushNamed(context, AppPage.routeInfo);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                      child: DestinationButton(
                        destination: "Technische Universität",
                        onPressed: () async {
                          // await app.updateRoute(0, 0, 1, 1);
                          // Navigator.pushNamed(context, AppPage.routeInfo);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                      child: DestinationButton(
                        destination: "Pirnaischer Platz",
                        onPressed: () async {
                          // await app.updateRoute(0, 0, 1, 1);
                          // Navigator.pushNamed(context, AppPage.routeInfo);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                child: Text(
                  "Pilotstrecken",
                  style: TextStyle(fontSize: 23, color: Colors.white60),
                ),
              ),
              Column(
                children: statusService.pilotstrecken.strecken
                    .map(
                      (strecke) => new Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                        child: RouteButton(
                          index: strecke.index,
                          title: strecke.title,
                          start: strecke.startLabel,
                          destination: strecke.destinationLabel,
                          description: strecke.description,
                          onPressed: () async {
                            await app.updateRoute(
                              strecke.fromLat,
                              strecke.fromLon,
                              strecke.toLat,
                              strecke.toLon,
                            );
                            Navigator.pushNamed(context, AppPage.routeInfo);
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
