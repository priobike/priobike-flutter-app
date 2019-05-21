import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import 'package:bike_now/widgets/location_point_widget.dart';
import 'package:bike_now/pages/route_information_page.dart';

class MapBoxWidget extends StatefulWidget {
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
  MapNotifier notifier;
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
    this.mapController = controller;
    mapController.addCircle(
        CircleOptions(
            geometry: LatLng(
              51.02,
              13.12
            ),
            circleColor: "#FF0000",
            circleRadius: 30)
    );
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
            CameraPosition(target: LatLng(_currentLocation.latitude, _currentLocation.longitude), zoom: 11.0));
  }
}
