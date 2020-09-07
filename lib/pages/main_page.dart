import 'package:bikenow/config/router.dart';
import 'package:bikenow/models/api/api_pilotstrecken.dart';
import 'package:bikenow/services/status_service.dart';
import 'package:bikenow/services/app_service.dart';
import 'package:bikenow/widgets/route_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MainPageState();
  }
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppService>(context);
    final statusService = Provider.of<StatusService>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          app.loading ? "BikeNow Dresden (lade...)" : "BikeNow Dresden",
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppPage.settings),
          ),
        ],
      ),
      body: statusService.pilotstrecken != null
          ? new ListView.builder(
              itemCount: statusService.pilotstrecken.strecken.length,
              itemBuilder: (BuildContext ctxt, int index) {
                ApiStrecke strecke =
                    statusService.pilotstrecken.strecken[index];

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: new RouteButton(
                    title: strecke.title,
                    start: strecke.startLabel,
                    destination: strecke.destinationLabel,
                    description: strecke.description,
                    colors: [
                      Color(0x00000000),
                      Color(0x00000000),
                    ],
                    onPressed: () async {
                      await app.updateRoute(strecke.fromLat, strecke.fromLon,
                          strecke.toLat, strecke.toLon);
                      Navigator.pushNamed(context, AppPage.routeInfo);
                    },
                  ),
                );
              })
          : Text('asd'),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppPage.routeCreation);
        },
        child: Icon(
          Icons.add,
        ),
        elevation: 5,
      ),
    );
  }
}
