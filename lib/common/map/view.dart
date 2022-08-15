import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/service.dart';
import 'package:provider/provider.dart';

class AppMap extends StatefulWidget {
  /// A callback that is executed when the map was created.
  final void Function(MapboxMapController)? onMapCreated;

  /// A callback that is executed when the style was loaded.
  final void Function()? onStyleLoaded;

  const AppMap({
    this.onMapCreated,
    this.onStyleLoaded,
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
      styleString: "mapbox://styles/mapbox/light-v10",
      accessToken: "pk.eyJ1Ijoic25ybXR0aHMiLCJhIjoiY2w0ZWVlcWt5MDAwZjNjbW5nMHNvN3kwNiJ9.upoSvMqKIFe3V_zPt1KxmA",
      onMapCreated: widget.onMapCreated,
      onStyleLoadedCallback: widget.onStyleLoaded,
      attributionButtonPosition: AttributionButtonPosition.BottomRight,
      initialCameraPosition: CameraPosition(
        target: settingsService.backend.center,
        tilt: 0,
        zoom: 11
      ),
    );
  }
}