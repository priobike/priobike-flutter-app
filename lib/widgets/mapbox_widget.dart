import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import 'package:bike_now/widgets/location_point_widget.dart';
import 'package:bike_now/pages/route_information_page.dart';
import 'package:bike_now/models/models.dart' as BikeNow;

import 'package:bike_now/models/route.dart' as BikeRoute;

class MapBoxWidget extends StatefulWidget {
  BikeRoute.Route route;
  BikeNow.LatLng currentLocation;

  MapBoxWidget(this.route, this.currentLocation);

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
  Circle position;


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

  void _onMapCreated(MapboxMapController controller) async {
    var coordinateList = widget.route.coordinates.map((coordinate) => coordinate.toMapBoxCoordinates()).toList();
    List<BikeNow.LSA> lsas = widget.route.getLSAs();
    this.mapController = controller;
    mapController.addLine(
      LineOptions(
        geometry: coordinateList,
        lineColor: "#ff0000",
        lineWidth: 7.0,
        lineOpacity: 0.7,
    ));
    lsas.forEach((lsa) {
      mapController.addCircle(
        CircleOptions(
          geometry: LatLng(lsa.lat, lsa.lon),
          circleColor: "#000000",
          circleRadius: 10
        )
      );
    });
    if(widget.currentLocation != null){
      position = await mapController.addCircle(
          CircleOptions(
              geometry: widget.currentLocation.toMapBoxCoordinates(),
              circleColor: '#ff00ff',
              circleRadius: 5
          )
      );
    }


  }

  initPlatformState() async {
    _currentLocation = await location.getLocation();
  }

  void centerTargetPosition() {
    mapController.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(_currentLocation.latitude, _currentLocation.longitude))));
    
  }

  @override
  Widget build(BuildContext context) {
    if(mapController != null){
      mapController.updateCircle(position, CircleOptions(
          geometry: widget.currentLocation.toMapBoxCoordinates(),
          circleColor: '#ff00ff',
          circleRadius: 5
      ));
    }

    // TODO: implement build
    return MapboxMap(
      onMapCreated: _onMapCreated,
      myLocationEnabled: false,
        compassEnabled: false,
        initialCameraPosition:
            CameraPosition(target: widget.route.coordinates.first.toMapBoxCoordinates(), zoom: 11.0));
  }
}
