import 'package:bike_now/blocs/bloc_manager.dart';
import 'package:bike_now/blocs/route_information_bloc.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import 'package:bike_now/widgets/location_point_widget.dart';
import 'package:bike_now/pages/route_information_page.dart';
import 'package:bike_now/models/models.dart' as BikeNow;

import 'package:bike_now/models/route.dart' as BikeRoute;

class RouteInformationMap extends StatelessWidget {
  MapboxMapController mapController;
  RouteInformationBloc routeInformationBloc;
  BikeNow.Route route;

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
  }

  @override
  Widget build(BuildContext context) {
    routeInformationBloc = Provider.of<ManagerBloc>(context).routeInformationBloc;

    // TODO: implement build
    return StreamBuilder<BikeNow.Route>(
      stream: routeInformationBloc.getRoute,
      initialData: null,
      builder: (context, snapshot) {
        if (snapshot.data == null){
          return Container();
        }
        route = snapshot.data;
        return MapboxMap(
            onMapCreated: _onMapCreated,
            myLocationEnabled: false,
            compassEnabled: false,
            initialCameraPosition:
            CameraPosition(target: route.coordinates.first.toMapBoxCoordinates(), zoom: 11.0));
      }
    );
  }
}
