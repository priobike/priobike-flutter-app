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

  String destination;

  void _onMapCreated(MapboxMapController controller) {
    this.controller = controller;
  }

  void _onStyleLoaded() {
    mapReady = true;
  }

  void drawRoute() {
    log.i('Draw ${selectedRoute.route.length} points as lines on map');

    for (var i = 0; i < selectedRoute.route.length - 1; i++) {
      ApiPoint point = selectedRoute.route[i];
      ApiPoint nextPoint = selectedRoute.route[i + 1];

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

    selectedRoute.signalgroups.forEach(
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
      drawRoute();
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
        title: Text("Navigiere zu"),
        elevation: PrioBikeTheme.buttonElevation,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: DestinationSearch(),
              ).then(
                (value) => setState(() {
                  destination = value;
                }),
              );
            },
          )
        ],
      ),
      body: Stack(
        children: <Widget>[
          MapboxMap(
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            initialCameraPosition: const CameraPosition(
              target: LatLng(51.050, 13.737),
              zoom: 12.0,
            ),
            styleString: MapboxStyles.DARK,
            myLocationEnabled: true,
            trackCameraPosition: true,
            onMapClick: (position, coordinates) {
              setState(() {
                destination = 'Eigenes Ziel';
              });

              this.controller.addCircle(
                    CircleOptions(
                      geometry: coordinates,
                      circleRadius: 6,
                      circleColor: 'blue',
                      circleStrokeWidth: 2,
                      circleStrokeColor: 'white',
                    ),
                  );

              app.updateDestination(
                coordinates.latitude,
                coordinates.longitude,
              );
            },
          ),
          if (destination != null)
            Positioned(
              bottom: 30.0,
              left: 10.0,
              right: 10.0,
              child: Card(
                elevation: 8.0,
                color: PrioBikeTheme.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: !app.loadingRoute
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Ziel: $destination',
                              style: textStyle,
                            ),
                            Text(
                              '${((app.route?.distance ?? 0) / 1000).toStringAsFixed(2)} Kilometer',
                              style: textStyle,
                            ),
                            Text(
                              '${Duration(milliseconds: app.route?.time ?? 0).inMinutes} Minuten Fahrzeit',
                              style: textStyle,
                            ),
                            Text(
                              '${(app.route?.signalgroups?.length ?? 0)} Ampeln',
                              style: textStyle,
                            ),
                            SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: RaisedButton.icon(
                                icon: Icon(
                                  Icons.navigation,
                                ),
                                label: Text("Losfahren"),
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppPage.navigation,
                                  );
                                  app.startNavigation();
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
                          ],
                        ),
                      )
                    : LinearProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    log.i("ChooseRoutePage disposed.");
    super.dispose();
  }
}

class DestinationSearch extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Ziel Suchen';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    print(query);
    return ListTile(
      title: Text(query),
      onTap: () => close(context, query),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListTile(
      title: Text(query),
      onTap: () => close(context, query),
    );
  }
}
