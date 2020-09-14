import 'package:bikenow/config/logger.dart';
import 'package:bikenow/config/palette.dart';
import 'package:bikenow/config/router.dart';
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
    controller.addLine(
      LineOptions(
        geometry: [
          LatLng(51.0657400157, 13.746932744),
          LatLng(51.0315101741, 13.725619912),
        ],
        lineColor: "#ff0000",
        lineWidth: 8.0,
        lineOpacity: 1,
      ),
    );
  }

  // void onStyleLoadedCallback() {
  //   List<ApiPoint> pointlist = [];

  //   selectedRoute.instructions.forEach(
  //       (ApiInstruction instruction) => pointlist += instruction.points);

  //   log.i('Draw ${pointlist.length} points as lines on map');

  //   for (var i = 0; i < pointlist.length - 1; i++) {
  //     ApiPoint point = pointlist[i];
  //     ApiPoint nextPoint = pointlist[i + 1];

  //     controller.addLine(
  //       LineOptions(
  //         geometry: [
  //           LatLng(point.lat, point.lon),
  //           LatLng(nextPoint.lat, nextPoint.lon)
  //         ],
  //         lineColor: "#00274C",
  //         lineWidth: 8.0,
  //         lineOpacity: 1,
  //         lineJoin: 'line-join', // does not work yet
  //       ),
  //     );
  //   }

  //   selectedRoute.sg.forEach(
  //     (sg) => {
  //       controller.addCircle(
  //         CircleOptions(
  //           geometry: LatLng(
  //             sg.lat,
  //             sg.lon,
  //           ),
  //           circleRadius: 6,
  //           circleColor: 'red',
  //           circleStrokeWidth: 2,
  //           circleStrokeColor: 'white',
  //         ),
  //       )
  //     },
  //   );
  // }

  AppService app;

  @override
  void didChangeDependencies() {
    app = Provider.of<AppService>(context);
    selectedRoute = app.route;
    // app.startGeolocation();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    print(app.route);
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.background,
        title: Text("Streckenvorschau"),
        elevation: 0,
      ),
      body: app.loading == false
          ? Column(
              children: <Widget>[
                Expanded(
                  child: MapboxMap(
                    onMapCreated: _onMapCreated,
                    onStyleLoadedCallback: onStyleLoadedCallback,
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(51.050, 13.737),
                      zoom: 12.0,
                    ),
                    styleString: MapboxStyles.DARK,
                    myLocationEnabled: false,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Distanz: ${((app.route?.distance ?? 0) / 1000).toStringAsFixed(2)} Kilometer',
                      style: TextStyle(
                        color: Palette.text,
                      ),
                    ),
                    Text(
                      'Ampeln: ${(app.route?.sg?.length ?? 0)}',
                      style: TextStyle(
                        color: Palette.text,
                      ),
                    ),
                    Text(
                      'Dauer: ${Duration(milliseconds: app.route?.time ?? 0).inMinutes} Minuten',
                      style: TextStyle(
                        color: Palette.text,
                      ),
                    ),
                    Text(
                      'Anstieg: ${(app.route?.ascend ?? 0)} Meter',
                      style: TextStyle(
                        color: Palette.text,
                      ),
                    ),
                    Text(
                      'Gefälle: ${(app.route?.descend ?? 0)} Meter',
                      style: TextStyle(
                        color: Palette.text,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: RaisedButton.icon(
                      padding: EdgeInsets.all(12),
                      icon: Icon(
                        Icons.location_on,
                      ),
                      label: Text("Routing Starten"),
                      onPressed: () {
                        Navigator.pushNamed(context, AppPage.navigation);
                      },
                      elevation: 2,
                      color: Palette.button,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Text(
              "Lade Route...",
              style: TextStyle(color: Palette.text),
            )),
    );
  }

  @override
  void dispose() {
    // app.stopGeolocation();
    controller.dispose();
    super.dispose();
  }
}
