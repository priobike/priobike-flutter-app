import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:priobike/common/map/map_design.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';

class AppMap extends StatefulWidget {
  /// A callback that is executed when the map was created.
  final void Function(mapbox.MapboxMap)? onMapCreated;

  /// A callback that is executed when the style was loaded.
  final void Function(mapbox.StyleLoadedEventData)? onStyleLoaded;

  /// A callback that is executed when the camera position changes.
  final void Function(mapbox.CameraChangedEventData)? onCameraChanged;

  /// A callback that is executed when the map is longclicked.
  final void Function(mapbox.MapContentGestureContext)? onMapLongClick;

  /// A callback that is executed when the map is taped.
  final void Function(mapbox.MapContentGestureContext)? onMapTap;

  /// A callback that is executed when the map is scrolled.
  final void Function(mapbox.MapContentGestureContext)? onMapScroll;

  /// A callback that is executed when the map is scrolled.
  final void Function(mapbox.MapIdleEventData)? onMapIdle;

  /// The margins for the Mapbox logo.
  /// (where those margins get applied depends on the corresponding ornament position)
  final Point<num>? logoViewMargins;

  /// The ornament position for the Mapbox logo.
  final mapbox.OrnamentPosition? logoViewOrnamentPosition;

  /// The margins for the attribution button
  /// (where those margins get applied depends on the corresponding ornament position)
  final Point<num>? attributionButtonMargins;

  /// The ornament position for the atrribution button.
  final mapbox.OrnamentPosition? attributionButtonOrnamentPosition;

  /// If the energy saving mode should be used.
  final bool saveBatteryModeEnabled;

  /// Use the Mapbox positioning.
  final bool useMapboxPositioning;

  const AppMap(
      {this.onMapCreated,
      this.onStyleLoaded,
      this.onCameraChanged,
      this.onMapLongClick,
      this.onMapIdle,
      this.onMapTap,
      this.onMapScroll,
      this.logoViewMargins,
      this.logoViewOrnamentPosition,
      this.attributionButtonMargins,
      this.attributionButtonOrnamentPosition,
      this.saveBatteryModeEnabled = false,
      this.useMapboxPositioning = false,
      super.key});

  @override
  AppMapState createState() => AppMapState();
}

class AppMapState extends State<AppMap> {
  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The associated layers service.
  late MapDesigns mapDesigns;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    settings = getIt<Settings>();
    settings.addListener(update);
    mapDesigns = getIt<MapDesigns>();
    mapDesigns.addListener(update);
  }

  @override
  void dispose() {
    settings.removeListener(update);
    mapDesigns.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    if (widget.saveBatteryModeEnabled) {
      devicePixelRatio = devicePixelRatio / Settings.scalingFactor;
    }

    final Widget map = mapbox.MapWidget(
      key: const ValueKey("mapbox-map"),
      styleUri: Theme.of(context).colorScheme.brightness == Brightness.light
          ? mapDesigns.mapDesign.lightStyle
          : mapDesigns.mapDesign.darkStyle,
      onMapCreated: onMapCreated,
      onStyleLoadedListener: widget.onStyleLoaded,
      onTapListener: widget.onMapTap,
      onLongTapListener: widget.onMapLongClick,
      onCameraChangeListener: widget.onCameraChanged,
      onMapIdleListener: widget.onMapIdle,
      onScrollListener: widget.onMapScroll,
      // ONLY AFFECTS ANDROID
      // If set to false, surfaceView is used instead.
      // "Although SurfaceView is very efficient, it might not fit all use cases as it creates a separate window and
      // cannot be moved, transformed, or animated. For these situations where you need more flexibility,
      // it’s usually best to use a TextureView. This is less performant than SurfaceView, but it behaves as a standard
      // View and can be manipulated as such." https://blog.mapbox.com/asynchronous-rendering-on-android-831722ac1837
      // We use this to mitigate blank maps (observed when using the surfaceView and using the app excessively
      // (e.g. starting a lot of rides/opening and closing map views without closing the app in between))
      textureView: true,
      // Using TLHC since this is the recommended hosting mode and VD as fallback to make sure performance is not an issue.
      // See: https://github.com/flutter/flutter/wiki/Android-Platform-Views for more detailed information.
      androidHostingMode: mapbox.AndroidPlatformViewHostingMode.TLHC_VD,
      mapOptions: mapbox.MapOptions(
        // Setting this to UNIQUE allows Mapbox to perform optimizations (only possible if the GL context is not
        // shared (not used by other frameworks/code except Mapbox))
        contextMode: mapbox.ContextMode.UNIQUE,
        crossSourceCollisions: false,
        pixelRatio: devicePixelRatio,
      ),
      cameraOptions: mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(
            settings.city.center.longitude,
            settings.city.center.latitude,
          ),
        ),
        zoom: 12,
      ),
    );

    // Render map with 2.5x size if battery saving mode is enabled.
    // This results in the end in a lower resolution of the map and thus a lower GPU load and energy consumption.
    return widget.saveBatteryModeEnabled && Platform.isAndroid
        ? Transform.scale(
            scale: Settings.scalingFactor,
            child: map,
          )
        : map;
  }

  /// A wrapper for the default onMapCreated callback.
  /// In this callback we configure the default settings.
  Future<void> onMapCreated(mapbox.MapboxMap controller) async {
    if (widget.useMapboxPositioning) {
      controller.location.updateSettings(mapbox.LocationComponentSettings(
        enabled: true,
        puckBearingEnabled: true,
        puckBearing: mapbox.PuckBearing.HEADING,
      ));
    }
    controller.compass.updateSettings(mapbox.CompassSettings(enabled: false));
    controller.scaleBar.updateSettings(mapbox.ScaleBarSettings(enabled: false));
    controller.attribution.updateSettings(mapbox.AttributionSettings(
        clickable: true,
        position: widget.attributionButtonOrnamentPosition,
        marginTop: widget.attributionButtonOrnamentPosition == mapbox.OrnamentPosition.TOP_RIGHT &&
                widget.attributionButtonMargins != null
            ? widget.attributionButtonMargins!.y.toDouble()
            : 0,
        marginBottom: widget.attributionButtonOrnamentPosition == mapbox.OrnamentPosition.BOTTOM_RIGHT &&
                widget.attributionButtonMargins != null
            ? widget.attributionButtonMargins?.y.toDouble()
            : 0,
        marginRight: widget.attributionButtonMargins?.x.toDouble()));
    controller.logo.updateSettings(mapbox.LogoSettings(
        position: widget.logoViewOrnamentPosition,
        marginTop: widget.logoViewOrnamentPosition == mapbox.OrnamentPosition.TOP_LEFT && widget.logoViewMargins != null
            ? widget.logoViewMargins!.y.toDouble()
            : 0,
        marginBottom:
            widget.logoViewOrnamentPosition == mapbox.OrnamentPosition.BOTTOM_LEFT && widget.logoViewMargins != null
                ? widget.logoViewMargins!.y.toDouble()
                : 0,
        marginLeft: widget.logoViewMargins?.x.toDouble()));
    widget.onMapCreated?.call(controller);
  }
}
