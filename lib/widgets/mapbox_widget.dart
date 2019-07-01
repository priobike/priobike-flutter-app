import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import 'package:bike_now/widgets/location_point_widget.dart';
import 'package:bike_now/pages/route_information_page.dart';

import 'package:bike_now/models/route.dart' as BikeRoute;
class MapBoxWidget extends StatefulWidget {
  BikeRoute.Route route;

  MapBoxWidget(this.route);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _MapBoxState();
  }
}

class _MapBoxState extends State<MapBoxWidget> {
  var location;
  LocationData _targetLocation;
  LocationData _currentLocation;
  MapboxMapController mapController;


  _MapBoxState() {
    location = new Location();
    location.onLocationChanged().listen((LocationData currentLocation) {
      setState(() {
        _currentLocation = currentLocation;

      });
    });
  }
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void _onMapCreated(MapboxMapController controller) {
    var coordinateList = widget.route.coordinates.map((coordinate) => coordinate.toMapBoxCoordinates()).toList();
    this.mapController = controller;

    mapController.addLine(
      LineOptions(
        geometry: coordinateList,
        lineColor: "#ff0000",
        lineWidth: 7.0,
        lineOpacity: 0.7,
    ));
  }

  initPlatformState() async {
    _currentLocation = await location.getLocation();
  }

  void centerTargetPosition() {
    mapController.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(_currentLocation.latitude, _currentLocation.longitude))));
    
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MapboxMap(
      onMapCreated: _onMapCreated,
      myLocationEnabled: true,
        compassEnabled: false,
        initialCameraPosition:
            CameraPosition(target: widget.route.coordinates.first.toMapBoxCoordinates(), zoom: 11.0));
  }
}
