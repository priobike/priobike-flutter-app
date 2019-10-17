import 'dart:async';

import 'package:bike_now_flutter/blocs/bloc_manager.dart';
import 'package:bike_now_flutter/blocs/route_creation_bloc.dart';
import 'package:bike_now_flutter/blocs/route_information_bloc.dart';
import 'package:bike_now_flutter/helper/palette.dart';
import 'package:bike_now_flutter/pages/route_creation_page.dart';
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
  RouteCreationBloc routeCreationBloc;
  // Route to show
  List<LatLng> _coordinates = [];
  List<LatLng> get coordinates => _coordinates;
  set coordinates(List<LatLng> value) {
    _coordinates = value;
  }

  BikeNow.Route _route;
  BikeNow.Route get route => _route;
  set route(BikeNow.Route value) {
    if(value != null){
      _route = value;
      coordinates = _route.coordinates
          .map((coordinate) => coordinate.toGoogleLatLng())
          .toList();
    }
    setState(() {
      _polylines.clear();
      _marker.clear();
      _polylineIdCounter = 0;
      _markerIdCounter = 0;
      _polylines.add(Polyline(
          polylineId: PolylineId((_polylineIdCounter++).toString()),
          points: coordinates,
          visible: true,
          color: Palette.primaryColor));
      _marker.add(Marker(
          markerId: MarkerId((_markerIdCounter++).toString()),
          position: coordinates?.first,
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: 'Start')));
      _marker.add(Marker(
          markerId: MarkerId((_markerIdCounter++).toString()),
          position: coordinates?.last,
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: 'Ziel')));
    });

  }

  // MapProperties
  Completer<GoogleMapController> _controller = Completer();
  Set<Polyline> _polylines = {};
  int _polylineIdCounter = 0;
  Set<Marker> _marker = {};
  int _markerIdCounter = 0;

  static final LatLng _kGooglePlex = LatLng(51.029334, 13.728900);

  @override
  void didChangeDependencies() {
    routeCreationBloc = Provider.of<ManagerBloc>(context).routeCreationBlog;
    routeCreationBloc.getRoute.listen((route){
      this.route = route;
    });
    super.didChangeDependencies();
  }

  void _onMapCreated(GoogleMapController controller) async {
    _controller.complete(controller);
  }

  @override
  Widget build(BuildContext context) {
          return GoogleMap(
              mapType: MapType.normal,
              polylines: _polylines,
              markers: _marker,
              myLocationEnabled: true,
              compassEnabled: true,
              initialCameraPosition: CameraPosition(
                  target: _route?.coordinates?.first?.toGoogleLatLng() ?? _kGooglePlex, zoom: 11),
              onMapCreated: _onMapCreated,
            );

  }
}
