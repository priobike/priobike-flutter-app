import 'package:bike_now_flutter/blocs/bloc_manager.dart';
import 'package:bike_now_flutter/blocs/route_information_bloc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bike_now_flutter/models/models.dart' as BikeNow;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteInformationMap extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RouteInformationMapState();
  }
}

class _RouteInformationMapState extends State<RouteInformationMap> {
  //Blocs
  RouteInformationBloc routeInformationBloc;
  // Route to show
  List<LatLng> _coordinates;
  List<LatLng> get coordinates => _coordinates;
  set coordinates(List<LatLng> value) {
    _coordinates = value;
  }

  BikeNow.Route _route;
  BikeNow.Route get route => _route;
  set route(BikeNow.Route value) {
    _route = value;
    coordinates = _route.coordinates
        .map((coordinate) => coordinate.toGoogleLatLng())
        .toList();
  }

  // MapProperties
  GoogleMapController controller;
  Set<Polyline> _polylines = {};
  int _polylineIdCounter = 0;
  Set<Marker> _marker = {};
  int _markerIdCounter = 0;

  @override
  void didChangeDependencies() {
    routeInformationBloc =
        Provider.of<ManagerBloc>(context).routeInformationBloc;
    routeInformationBloc.getRoute.listen((route) => this.route = route);
    super.didChangeDependencies();
  }

  void _onMapCreated(GoogleMapController controller) async {
    setState(() {
      _polylines.add(Polyline(
          polylineId: PolylineId((_polylineIdCounter++).toString()),
          points: coordinates,
          visible: true,
          color: Colors.blue));
      _marker.add(Marker(
          markerId: MarkerId((_markerIdCounter++).toString()),
          position: coordinates.first,
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: 'Start')));
      _marker.add(Marker(
          markerId: MarkerId((_markerIdCounter++).toString()),
          position: coordinates.last,
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: 'Ziel')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BikeNow.Route>(
        stream: routeInformationBloc.getRoute,
        initialData: null,
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return Container();
          }
          return GoogleMap(
            mapType: MapType.normal,
            polylines: _polylines,
            markers: _marker,
            initialCameraPosition: CameraPosition(
                target: _route.coordinates.first.toGoogleLatLng(), zoom: 11),
            onMapCreated: _onMapCreated,
          );
        });
  }
}
