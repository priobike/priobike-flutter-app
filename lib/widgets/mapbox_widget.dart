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
    _circles.clear();
    _lsas.forEach((lsa) {
      setState(() {
        _circles.add(Circle(circleId: CircleId((_circleIdCounter++).toString()), center: LatLng(lsa.lat, lsa.lon), fillColor: Colors.red, radius: 8, visible: true, strokeWidth: 0, zIndex: 1));
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
    lsas = _route.getLSAs();
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
  Set<Circle> _circles  = {};
  int _circleIdCounter = 0;
  double zoomLevel = 15;


  @override
  void didChangeDependencies() {
    navigationBloc = Provider.of<ManagerBloc>(context).navigationBloc;
    locationController = Provider.of<ManagerBloc>(context).locationController;

    navigationBloc.getRoute.listen((route) => this.route = route);
    locationController.getCurrentLocation.listen((location){
      currentLocation = location.toGoogleLatLng();
      centerMapToCurrentPosition();

    });
    super.didChangeDependencies();
  }



  void _onMapCreated(GoogleMapController controller) async {
    this.controller = controller;
    setState(() {
      _polylines.add(Polyline(polylineId: PolylineId((_polylineIdCounter++).toString()), points: coordinates, visible: true, color: Colors.blue, zIndex: 0));
      _marker.add(Marker(markerId: MarkerId((_markerIdCounter++).toString()), position: coordinates.first, icon: BitmapDescriptor.defaultMarker, zIndex: 2, infoWindow: InfoWindow(
          title: 'Start'
      )));
      _marker.add(Marker(markerId: MarkerId((_markerIdCounter++).toString()), position: coordinates.last, icon: BitmapDescriptor.defaultMarker, zIndex: 2, infoWindow: InfoWindow(title: 'Ziel') ));

    });
    }


  void centerMapToCurrentPosition() {
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: _currentLocation, zoom: zoomLevel)));

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
                target: _route.coordinates.first.toGoogleLatLng(), zoom: zoomLevel),
            onMapCreated: _onMapCreated,
          );
        });
  }
}
