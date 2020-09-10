import 'package:bikenow/config/router.dart';
import 'package:bikenow/services/app_service.dart';
import 'package:bikenow/services/status_service.dart';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              child: SizedBox(
                width: double.infinity,
                child: RaisedButton.icon(
                  padding: EdgeInsets.all(12),
                  icon: Icon(
                    Icons.location_on,
                  ),
                  label: Text(
                    "Zu Ziel navigieren",
                  ),
                  onPressed: () {},
                  elevation: 2,
                  color: Color(0xff222222),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(16.0),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
              child: SizedBox(
                width: double.infinity,
                child: RaisedButton.icon(
                  padding: EdgeInsets.all(12),
                  icon: Icon(Icons.directions_bike),
                  label: Text(
                    "Freie Fahrt",
                    textAlign: TextAlign.start,
                  ),
                  onPressed: () {},
                  elevation: 2,
                  color: Color(0xff222222),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(16.0),
                    ),
                  ),
                ),
              ),
            ),
            Text("Pilotstrecken",
                style: TextStyle(fontSize: 23, color: Colors.white60)),
            Column(
              children: statusService.pilotstrecken.strecken
                  .map(
                    (strecke) => new Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                      child: new RouteButton(
                        title: strecke.title,
                        start: strecke.startLabel,
                        destination: strecke.destinationLabel,
                        description: strecke.description,
                        onPressed: () async {
                          await app.updateRoute(strecke.fromLat,
                              strecke.fromLon, strecke.toLat, strecke.toLon);
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
    );
  }
}
