import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/service.dart';
import 'package:provider/provider.dart';

class AppMap extends StatefulWidget {
  /// If dragging is enabled.
  final bool dragEnabled;

  /// A callback that is executed when the map was created.
  final void Function(MapboxMapController)? onMapCreated;

  /// A callback that is executed when the style was loaded.
  final void Function()? onStyleLoaded;

  /// A callback that is executed when the camera is idle.
  final void Function()? onCameraIdle;

  /// A callback that is executed when the map is longclicked.
  final void Function(Point<double>, LatLng)? onMapLongClick;

  const AppMap({
    this.dragEnabled = true,
    this.onMapCreated,
    this.onStyleLoaded,
    this.onCameraIdle,
    this.onMapLongClick,
    Key? key
  }) : super(key: key);

  @override 
  AppMapState createState() => AppMapState();
}

class AppMapState extends State<AppMap> {
  /// The associated settings service, which is injected by the provider.
  late SettingsService settingsService;

  @override
  void didChangeDependencies() {
    settingsService = Provider.of<SettingsService>(context);
    super.didChangeDependencies();
  }

  @override 
  Widget build(BuildContext context) {
    return MapboxMap(
      styleString: "mapbox://styles/snrmtths/cl77mab5k000214mkk26ewqqu",
      accessToken: "pk.eyJ1Ijoic25ybXR0aHMiLCJhIjoiY2w0ZWVlcWt5MDAwZjNjbW5nMHNvN3kwNiJ9.upoSvMqKIFe3V_zPt1KxmA",
      onMapCreated: widget.onMapCreated,
      onStyleLoadedCallback: widget.onStyleLoaded,
      compassEnabled: false,
      dragEnabled: widget.dragEnabled,
      onCameraIdle: widget.onCameraIdle,
      onMapLongClick: widget.onMapLongClick,
      attributionButtonPosition: AttributionButtonPosition.BottomRight,
      initialCameraPosition: CameraPosition(
        target: settingsService.backend.center,
        tilt: 0,
        zoom: 11
      ),
    );
  }
}