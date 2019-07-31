import 'dart:async';

import 'package:bike_now/blocs/bloc_manager.dart';
import 'package:bike_now/blocs/navigation_bloc.dart';
import 'package:bike_now/controller/location_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bike_now/models/models.dart' as BikeNow;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapBoxWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MapBoxState();
  }
}

class _MapBoxState extends State<MapBoxWidget> {
  //Bloc and Services
  NavigationBloc navigationBloc;
  LocationController locationController;
  // Route to show
  List<LatLng> _coordinates;
  List<BikeNow.LSA> _lsas;
  set lsas(List<BikeNow.LSA> value) {
    _lsas = value;
    _lsas.forEach((lsa) {
      Color color = Colors.red;

      if (lsa.isCrossed != null) {
        if (lsa.isCrossed) {
          color = Colors.black45;
        }
      }
      setState(() {
        _circles.add(Circle(
            circleId: CircleId((_circleIdCounter++).toString()),
            center: LatLng(lsa.lat, lsa.lon),
            fillColor: color,
            radius: 14,
            visible: true,
            strokeWidth: 0,
            zIndex: 1));
      });
    });
  }

  List<BikeNow.GHNode> _ghNode;

  set ghNode(List<BikeNow.GHNode> value) {
    _ghNode = value;
    _ghNode.forEach((ghNode) {
      Color color = Colors.amber;
      if (ghNode.isCrossed != null) {
        if (ghNode.isCrossed) {
          color = Colors.black45;
        }
      }
      setState(() {
        _circles.add(Circle(
            circleId: CircleId((_circleIdCounter++).toString()),
            center: LatLng(ghNode.lat, ghNode.lon),
            fillColor: color,
            radius: 11,
            visible: true,
            strokeWidth: 0,
            zIndex: 1));
      });
    });
  }

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

    _circles.clear();
    lsas = _route.getLSAs();
    // draw ghNodes on Screen
    //ghNode = _route.getGHNodes(true);
  }

  // MapProperties
  GoogleMapController controller;
  LatLng _currentLocation;
  set currentLocation(LatLng value) {
    _currentLocation = value;
  }

  int currentLocationMarkerId;
  Set<Polyline> _polylines = {};
  int _polylineIdCounter = 0;
  Set<Marker> _marker = {};
  int _markerIdCounter = 0;
  Set<Circle> _circles = {};
  int _circleIdCounter = 0;
  double zoomLevel = 15;

  StreamSubscription<BikeNow.LatLng> subscription;

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    navigationBloc = Provider.of<ManagerBloc>(context).navigationBloc;
    locationController = Provider.of<ManagerBloc>(context).locationController;

    navigationBloc.getRoute.listen((route) => this.route = route);
    subscription = locationController.getCurrentLocation.listen((location) {
      currentLocation = location.toGoogleLatLng();
      centerMapToCurrentPosition();
    });
    super.didChangeDependencies();
  }

  void _onMapCreated(GoogleMapController controller) async {
    this.controller = controller;
    setState(() {
      _polylines.add(Polyline(
          polylineId: PolylineId((_polylineIdCounter++).toString()),
          points: coordinates,
          visible: true,
          color: Colors.blue,
          zIndex: 0));
      _marker.add(Marker(
          markerId: MarkerId((_markerIdCounter++).toString()),
          position: coordinates.first,
          icon: BitmapDescriptor.defaultMarker,
          zIndex: 2,
          infoWindow: InfoWindow(title: 'Start')));
      _marker.add(Marker(
          markerId: MarkerId((_markerIdCounter++).toString()),
          position: coordinates.last,
          icon: BitmapDescriptor.defaultMarker,
          zIndex: 2,
          infoWindow: InfoWindow(title: 'Ziel')));
    });
  }

  void centerMapToCurrentPosition() {
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentLocation, zoom: zoomLevel)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BikeNow.Route>(
        stream: navigationBloc.getRoute,
        initialData: null,
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return Container();
          }
          return GoogleMap(
            mapType: MapType.normal,
            polylines: _polylines,
            markers: _marker,
            circles: _circles,
            initialCameraPosition: CameraPosition(
                target: _route.coordinates.first.toGoogleLatLng(),
                zoom: zoomLevel),
            onMapCreated: _onMapCreated,
          );
        });
  }
}
