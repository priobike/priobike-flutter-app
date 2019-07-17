import 'package:bike_now/blocs/bloc_manager.dart';
import 'package:bike_now/blocs/navigation_bloc.dart';
import 'package:bike_now/controller/location_controller.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';

import 'package:bike_now/models/models.dart' as BikeNow;


class MapBoxWidget extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _MapBoxState();
  }
}

class _MapBoxState extends State<MapBoxWidget> {
  NavigationBloc navigationBloc;
  LocationController locationController;
  MapboxMapController mapController;

  Circle currentPositionCircle;
  BikeNow.Route route;
  LatLng currentLocation;

  @override
  void didChangeDependencies() {
    navigationBloc = Provider.of<ManagerBloc>(context).navigationBloc;
    locationController = Provider.of<ManagerBloc>(context).locationController;

    navigationBloc.getRoute.listen((route) => this.route = route);
    locationController.getCurrentLocation.listen((location){ currentLocation = location.toMapBoxCoordinates();
    updateCurrentPositionCircle();});
    super.didChangeDependencies();
  }

  void updateCurrentPositionCircle(){
    mapController.updateCircle(currentPositionCircle, CircleOptions(
      geometry: currentLocation,
    ));
    centerMapToCurrentPosition();

  }

  void _onMapCreated(MapboxMapController controller) async {
    var coordinateList = route.coordinates.map((coordinate) => coordinate.toMapBoxCoordinates()).toList();
    List<BikeNow.LSA> lsas = route.getLSAs();
    this.mapController = controller;
    mapController.addLine(
      LineOptions(
        geometry: coordinateList,
        lineColor: "#0000FF",
        lineWidth: 7.0,
        lineOpacity: 0.7,
    ));
    lsas.forEach((lsa) {
//      var Color = "#ff0000";
//      if (lsa.getSG().isGreen){
//        Color = "#00ff00";
//      }
      mapController.addCircle(
        CircleOptions(
          geometry: LatLng(lsa.lat, lsa.lon),
          circleColor: "#FF0000",
          circleRadius: 10
        )
      );
    });
    if(currentLocation != null && currentPositionCircle == null){
      currentPositionCircle = await mapController.addCircle(
          CircleOptions(
              geometry: currentLocation,
              circleColor: '#ff00ff',
              circleRadius: 5
          )
      );
    }
  }

  void centerMapToCurrentPosition() {
    mapController.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(target: currentLocation, zoom: 17),));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BikeNow.Route>(
        stream: navigationBloc.getRoute,
        builder: (context, routeSnapshot) {
                return MapboxMap(
                    onMapCreated: _onMapCreated,
                    myLocationEnabled: false,
                    compassEnabled: true,
                    initialCameraPosition:
                    CameraPosition(target: route.coordinates.first.toMapBoxCoordinates(), zoom: 17.0));
              }
          );
  }
}
