import 'package:priobike/config/priobike_theme.dart';
import 'package:priobike/config/router.dart';
import 'package:priobike/services/app_service.dart';
import 'package:priobike/services/status_service.dart';
import 'package:priobike/widgets/destination_button.dart';
import 'package:priobike/widgets/route_button.dart';
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
                    elevation: PrioBikeTheme.buttonElevation,
                    color: PrioBikeTheme.accentButton,
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
                        destination: "Ziel 1",
                        onPressed: () async {
                          // await app.updateRoute(0, 0, 1, 1);
                          // Navigator.pushNamed(context, AppPage.routeInfo);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                      child: DestinationButton(
                        destination: "Ziel 2",
                        onPressed: () async {
                          // await app.updateRoute(0, 0, 1, 1);
                          // Navigator.pushNamed(context, AppPage.routeInfo);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                      child: DestinationButton(
                        destination: "Ziel 3",
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
              statusService.pilotstrecken != null
                  ? Column(
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
                                  Navigator.pushNamed(
                                      context, AppPage.routeInfo);
                                },
                              ),
                            ),
                          )
                          .toList(),
                    )
                  : Text(
                      'Es konnten keine Pilotstrecken geladen werden',
                      style: TextStyle(color: Colors.white),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
