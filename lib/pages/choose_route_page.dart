import 'package:priobike/config/logger.dart';
import 'package:priobike/config/priobike_theme.dart';
import 'package:priobike/config/router.dart';
import 'package:priobike/models/api/api_point.dart';
import 'package:priobike/models/api/api_route.dart';
import 'package:priobike/services/app_service.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';

class ChooseRoutePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ChooseRoutePageState();
  }
}

class _ChooseRoutePageState extends State<ChooseRoutePage> {
  Logger log = new Logger('ChooseRoutePage');

  MapboxMapController controller;

  ApiRoute selectedRoute;

  bool mapReady = false;

  void _onMapCreated(MapboxMapController controller) {
    this.controller = controller;
  }

  void _onStyleLoaded() {
    mapReady = true;
    if (selectedRoute != null) drawRoute();
  }

  void drawRoute() {
    log.i('Draw ${selectedRoute.points.length} points as lines on map');

    for (var i = 0; i < selectedRoute.points.length - 1; i++) {
      ApiPoint point = selectedRoute.points[i];
      ApiPoint nextPoint = selectedRoute.points[i + 1];

      controller.addLine(
        LineOptions(
          geometry: [
            LatLng(point.lat, point.lon),
            LatLng(nextPoint.lat, nextPoint.lon)
          ],
          lineColor: "#0027ff",
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

    // controller.animateCamera(
    //   CameraUpdate.newLatLng(
    //     LatLng(selectedRoute.points[0].lat, selectedRoute.points[0].lon),
    //   ),
    // );
  }

  AppService app;

  @override
  void didChangeDependencies() {
    app = Provider.of<AppService>(context);
    selectedRoute = app.route;

    if (selectedRoute != null && mapReady == true) {
      // drawRoute();
    }

    if (!app.isGeolocating) {
      app.startGeolocation();
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = TextStyle(
      fontSize: 18,
      color: PrioBikeTheme.text,
    );

    return Scaffold(
      backgroundColor: PrioBikeTheme.background,
      appBar: AppBar(
        backgroundColor: PrioBikeTheme.background,
        title: Text("Streckenvorschau"),
        elevation: PrioBikeTheme.buttonElevation,
      ),
      body: app.loadingRoute == false
          ? Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: RaisedButton.icon(
                      padding: EdgeInsets.all(12),
                      icon: Icon(
                        Icons.location_searching,
                      ),
                      label: Text("Ziel suchen"),
                      onPressed: () {
                        print(controller.cameraPosition.target.toString());
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
                ),
                Expanded(
                  child: MapboxMap(
                    onMapCreated: _onMapCreated,
                    onStyleLoadedCallback: _onStyleLoaded,
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(51.050, 13.737),
                      zoom: 12.0,
                    ),
                    styleString: MapboxStyles.DARK,
                    myLocationEnabled: true,
                    trackCameraPosition: true,
                    onCameraIdle: () {
                      this.controller.addCircle(
                            CircleOptions(
                              geometry: LatLng(
                                  controller.cameraPosition.target.latitude,
                                  controller.cameraPosition.target.longitude),
                              circleRadius: 6,
                              circleColor: 'blue',
                              circleStrokeWidth: 2,
                              circleStrokeColor: 'white',
                            ),
                          );
                    },
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(8, 16, 8, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${((app.route?.distance ?? 0) / 1000).toStringAsFixed(2)} Kilometer',
                            style: textStyle,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${Duration(milliseconds: app.route?.time ?? 0).inMinutes} Minuten Fahrzeit',
                            style: textStyle,
                          ),
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          Text(
                            '${(app.route?.sg?.length ?? 0)} Ampeln',
                            style: textStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
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
                        Navigator.pushReplacementNamed(
                          context,
                          AppPage.navigation,
                        );
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
                ),
              ],
            )
          : Center(
              child: Text(
                "Lade Route...",
                style: TextStyle(color: PrioBikeTheme.text),
              ),
            ),
    );
  }

  @override
  void dispose() {
    log.i("ChooseRoutePage disposed.");
    super.dispose();
  }
}
