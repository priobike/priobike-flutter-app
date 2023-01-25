import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/logging/logger.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:turf/helpers.dart' as turf;

class AppMap extends StatefulWidget {
  /// Sideload prefetched mapbox tiles.
  /// NOTE: This feature is currently disabled.
  static Future<void> loadOfflineTiles() async {
    try {
      // At the moment, this will result in black maps being displayed.
      // Therefore we disable this feature for now.

      // await installOfflineMapTiles("assets/offline/hamburg-light.db");
      // await installOfflineMapTiles("assets/offline/hamburg-dark.db");
    } catch (err, stacktrace) {
      final hint = "Failed to load offline tiles: $err";
      Logger("AppMap").e(hint);
      if (!kDebugMode) {
        await Sentry.captureException(err, stackTrace: stacktrace, hint: hint);
      }
    }
  }

  /// A custom location puck image.
  final String? puckImage;

  /// A custom location puck image size.
  final double puckSize;

  /// If dragging is enabled.
  final bool dragEnabled;

  /// A callback that is executed when the map was created.
  final void Function(mapbox.MapboxMap)? onMapCreated;

  /// A callback that is executed when the style was loaded.
  final void Function(mapbox.StyleLoadedEventData)? onStyleLoaded;

  /// A callback that is executed when the camera is idle.
  final void Function()? onCameraIdle;

  /// A callback that is executed when the map is longclicked.
  final void Function(Point<double>, LatLng)? onMapLongClick;

  /// The attribution button position.
  // final AttributionButtonPosition attributionButtonPosition;

  final Point<num>? logoViewMargins;
  final Point<num>? attributionButtonMargins;

  const AppMap(
      {this.puckImage,
      this.puckSize = 128,
      this.dragEnabled = true,
      this.onMapCreated,
      this.onStyleLoaded,
      this.onCameraIdle,
      this.onMapLongClick,
      this.logoViewMargins,
      this.attributionButtonMargins,
      // this.attributionButtonPosition = AttributionButtonPosition.BottomRight,
      Key? key})
      : super(key: key);

  @override
  AppMapState createState() => AppMapState();
}

class AppMapState extends State<AppMap> {
  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The associated layers service.
  late Layers layers;

  @override
  void didChangeDependencies() {
    settings = Provider.of<Settings>(context);
    layers = Provider.of<Layers>(context);
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return mapbox.MapWidget(
      resourceOptions: mapbox.ResourceOptions(
          accessToken: "pk.eyJ1Ijoic25ybXR0aHMiLCJhIjoiY2w0ZWVlcWt5MDAwZjNjbW5nMHNvN3kwNiJ9.upoSvMqKIFe3V_zPt1KxmA"),
      key: const ValueKey("mapbox-map"),
      styleUri: Theme.of(context).colorScheme.brightness == Brightness.light
          ? layers.mapDesign.lightStyle
          : layers.mapDesign.darkStyle,
      onMapCreated: onMapCreated,
      onStyleLoadedListener: widget.onStyleLoaded,
      // Setting the following line (textureView) to true results in a spam of the message (only effects Android):
      // "updateAcquireFence: Did not find frame."
      // Setting the line (textureView) to false results in a spam of the message (only effects Android):
      // "[SurfaceTexture-0-26276-3](id:66a40000000b,api:1,p:627,c:26276) dequeueBuffer: BufferQueue has been abandoned"
      // Other effects were not yet observed.
      // textureView: false,
      cameraOptions: mapbox.CameraOptions(
        center: turf.Point(
            coordinates: turf.Position(
          settings.backend.center.longitude,
          settings.backend.center.latitude,
        )).toJson(),
        zoom: 12,
      ),
    );
  }

  /// A wrapper for the default onMapCreated callback.
  /// In this callback we configure the default settings.
  /// For example, we set the MapBox telemetry to disabled.
  Future<void> onMapCreated(mapbox.MapboxMap controller) async {
    // TODO find implementation/API to apply this in the new Mapbox plugin: "controller.setTelemetryEnabled(false);"
    controller.compass.updateSettings(mapbox.CompassSettings(enabled: false));
    controller.scaleBar.updateSettings(mapbox.ScaleBarSettings(enabled: false));
    controller.attribution.updateSettings(mapbox.AttributionSettings(clickable: true, position: mapbox.OrnamentPosition.BOTTOM_RIGHT, marginBottom: widget.attributionButtonMargins?.y.toDouble(), marginRight: widget.attributionButtonMargins?.x.toDouble()));
    controller.logo.updateSettings(mapbox.LogoSettings(position: mapbox.OrnamentPosition.BOTTOM_LEFT, marginBottom: widget.logoViewMargins?.y.toDouble(), marginLeft: widget.logoViewMargins?.x.toDouble()));
    widget.onMapCreated?.call(controller);
  }
}
