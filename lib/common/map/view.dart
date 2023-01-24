import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/routing/services/layers.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
  final void Function(MapboxMapController)? onMapCreated;

  /// A callback that is executed when the style was loaded.
  final void Function()? onStyleLoaded;

  /// A callback that is executed when the camera is idle.
  final void Function()? onCameraIdle;

  /// A callback that is executed when the map is dismissed from camera tracking.
  final void Function()? onCameraTrackingDismissed;

  /// A callback that is executed when the map is longclicked.
  final void Function(Point<double>, LatLng)? onMapLongClick;

  /// A callback that is executed when the map is longclicked.
  final void Function(Point<double>, LatLng)? onMapClick;

  /// The attribution button position.
  final AttributionButtonPosition attributionButtonPosition;

  /// The myLocationTrackingMode
  final MyLocationTrackingMode? myLocationTrackingMode;

  final Point<num>? logoViewMargins;
  final Point<num>? attributionButtonMargins;

  const AppMap(
      {this.puckImage,
      this.puckSize = 128,
      this.dragEnabled = true,
      this.onMapCreated,
      this.onStyleLoaded,
      this.onCameraIdle,
      this.onMapClick,
      this.onMapLongClick,
      this.logoViewMargins,
      this.attributionButtonMargins,
      this.attributionButtonPosition = AttributionButtonPosition.BottomRight,
      this.onCameraTrackingDismissed,
      this.myLocationTrackingMode,
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
  Widget build(BuildContext context) {
    return MapboxMap(
      styleString: Theme.of(context).colorScheme.brightness == Brightness.light
          ? layers.mapDesign.lightStyle
          : layers.mapDesign.darkStyle,
      // At the moment, we hard code the map box access token. In the future,
      // this token will be provided by an environment variable. However, we need
      // to integrate this in the CI builds and provide a development guide.
      accessToken: "pk.eyJ1Ijoic25ybXR0aHMiLCJhIjoiY2w0ZWVlcWt5MDAwZjNjbW5nMHNvN3kwNiJ9.upoSvMqKIFe3V_zPt1KxmA",
      onMapCreated: onMapCreated,
      onStyleLoadedCallback: widget.onStyleLoaded,
      trackCameraPosition: true,
      compassEnabled: false,
      dragEnabled: widget.dragEnabled,
      onCameraIdle: widget.onCameraIdle,
      onMapClick: widget.onMapClick,
      onMapLongClick: widget.onMapLongClick,
      onCameraTrackingDismissed: widget.onCameraTrackingDismissed,
      attributionButtonPosition: widget.attributionButtonPosition,
      myLocationEnabled: true,
      // Only used in new routing view.
      myLocationTrackingMode: widget.myLocationTrackingMode ?? MyLocationTrackingMode.None,
      myLocationRenderMode: MyLocationRenderMode.GPS,
      // Use a custom foreground image for the location puck.
      puckImage: widget.puckImage,
      puckSize: widget.puckSize,
      // Point on the test location center, which is Dresden or Hamburg.
      initialCameraPosition: CameraPosition(target: settings.backend.center, tilt: 0, zoom: 12),
      // The position of the logo and the attribution button.
      // Both are usually at the same height on different sides of the map.
      logoViewMargins: widget.logoViewMargins,
      attributionButtonMargins: widget.attributionButtonMargins,
    );
  }

  /// A wrapper for the default onMapCreated callback.
  /// In this callback we configure the default settings.
  /// For example, we set the MapBox telemetry to disabled.
  Future<void> onMapCreated(MapboxMapController controller) async {
    controller.setTelemetryEnabled(false);
    widget.onMapCreated?.call(controller);
  }
}
