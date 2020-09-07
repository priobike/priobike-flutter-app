import 'package:bikenow/config/logger.dart';
import 'package:bikenow/config/router.dart';
import 'package:bikenow/models/api/api_point.dart';
import 'package:bikenow/models/api/api_instruction.dart';
import 'package:bikenow/models/api/api_route.dart';
import 'package:bikenow/services/app_service.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';

class RouteInfoPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RouteInfoPageState();
  }
}

class _RouteInfoPageState extends State<RouteInfoPage> {
  Logger log = new Logger('RouteInfoPage');

  MapboxMapController controller;

  ApiRoute selectedRoute;

  void _onMapCreated(MapboxMapController controller) {
    this.controller = controller;
  }

  void onStyleLoadedCallback() {
    List<ApiPoint> pointlist = [];

    selectedRoute.instructions.forEach(
        (ApiInstruction instruction) => pointlist += instruction.points);

    log.i('Draw ${pointlist.length} points as lines on map');

    for (var i = 0; i < pointlist.length - 1; i++) {
      ApiPoint point = pointlist[i];
      ApiPoint nextPoint = pointlist[i + 1];

      controller.addLine(
        LineOptions(
          geometry: [
            LatLng(point.lat, point.lon),
            LatLng(nextPoint.lat, nextPoint.lon)
          ],
          lineColor: "#00274C",
          lineWidth: 8.0,
          lineOpacity: 1,
          lineJoin: 'line-join', // does not work yet
        ),
      );
    }

    selectedRoute.sg.forEach(
      (sg) => {
        controller.addCircle(
          CircleOptions(
            geometry: LatLng(
              sg.lat,
              sg.lon,
            ),
            circleRadius: 6,
            circleColor: 'red',
            circleStrokeWidth: 2,
            circleStrokeColor: 'white',
          ),
        )
      },
    );
  }

  AppService app;

  @override
  void didChangeDependencies() {
    app = Provider.of<AppService>(context);
    selectedRoute = app.route;
    app.startGeolocation();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text("Streckenvorschau"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: MapboxMap(
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: onStyleLoadedCallback,
              initialCameraPosition: const CameraPosition(
                target: LatLng(51.050, 13.737),
                zoom: 12.0,
              ),
              styleString: MapboxStyles.MAPBOX_STREETS,
              myLocationEnabled: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                          'Distanz: ${((app.route.distance ?? 0) / 1000).toStringAsFixed(2)} Kilometer'),
                      Text(
                          'Ampeln: ${(app.route?.sg?.length ?? 0)}'),
                      Text(
                          'Dauer: ${Duration(milliseconds: app.route?.time).inMinutes} Minuten'),
                      Text(
                          'Anstieg: ${(app.route?.ascend ?? 0)} Meter'),
                      Text(
                          'Gefälle: ${(app.route?.descend ?? 0)} Meter'),
                    ],
                  ),
                ),
                IconButton(
                    icon: Icon(Icons.directions_bike),
                    tooltip: 'Routing Starten',
                    onPressed: () {
                      Navigator.pushNamed(context, AppPage.navigation);
                    }),
                Text("Start")
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    print('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAa');
    app.stopGeolocation();
    controller.dispose();
    super.dispose();
  }
}
