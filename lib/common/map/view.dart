import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class AppMap extends StatefulWidget {
  /// Sideload prefetched mapbox tiles.
  /// NOTE: This feature is currently disabled. 
  static Future<void> loadOfflineTiles() async {
    try {
      // At the moment, this will result in black maps being displayed.
      // Therefore we disable this feature for now.

      // await installOfflineMapTiles("assets/offline/hamburg-light.db");
      // await installOfflineMapTiles("assets/offline/hamburg-dark.db");
    } catch (err) {
      Logger("AppMap").e("Failed to load offline tiles: $err");
    }
  }

  /// A custom location puck image.
  final String? puckImage;

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

  /// The attribution button position.
  final AttributionButtonPosition attributionButtonPosition;

  const AppMap({
    this.puckImage,
    this.dragEnabled = true,
    this.onMapCreated,
    this.onStyleLoaded,
    this.onCameraIdle,
    this.onMapLongClick,
    this.attributionButtonPosition = AttributionButtonPosition.BottomRight,
    Key? key
  }) : super(key: key);

  @override 
  AppMapState createState() => AppMapState();
}

class AppMapState extends State<AppMap> {
  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  @override
  void didChangeDependencies() {
    settings = Provider.of<Settings>(context);
    super.didChangeDependencies();
  }

  @override 
  Widget build(BuildContext context) {
    return MapboxMap(
      styleString: Theme.of(context).colorScheme.brightness == Brightness.light 
        // Use a custom light style that adds some more color to the light theme.
        ? "mapbox://styles/snrmtths/cl77mab5k000214mkk26ewqqu"
        : "mapbox://styles/mapbox/dark-v10" ,
      // At the moment, we hard code the map box access token. In the future,
      // this token will be provided by an environment variable. However, we need
      // to integrate this in the CI builds and provide a development guide.
      accessToken: "pk.eyJ1Ijoic25ybXR0aHMiLCJhIjoiY2w0ZWVlcWt5MDAwZjNjbW5nMHNvN3kwNiJ9.upoSvMqKIFe3V_zPt1KxmA",
      onMapCreated: widget.onMapCreated,
      onStyleLoadedCallback: widget.onStyleLoaded,
      compassEnabled: false,
      dragEnabled: widget.dragEnabled,
      onCameraIdle: widget.onCameraIdle,
      onMapLongClick: widget.onMapLongClick,
      myLocationEnabled: true,
      myLocationRenderMode: MyLocationRenderMode.COMPASS,
      myLocationTrackingMode: MyLocationTrackingMode.None,
      // Use a custom foreground image for the location puck.
      puckImage: widget.puckImage,
      puckSize: 128,
      attributionButtonPosition: widget.attributionButtonPosition,
      // Point on the test location center, which is Dresden or Hamburg.
      initialCameraPosition: CameraPosition(
        target: settings.backend.center,
        tilt: 0,
        zoom: 12
      ),
    );
  }
}