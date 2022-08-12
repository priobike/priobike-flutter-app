import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class AppMap extends MapboxMap {
  const AppMap({
    Key? key,
    CameraPosition initialCameraPosition = const CameraPosition(
      target: LatLng(53.551086, 9.993682), // Hamburg
      tilt: 0,
      zoom: 10
    ),
    void Function(MapboxMapController)? onMapCreated,
    void Function()? onStyleLoaded,
    AttributionButtonPosition? attributionButtonPosition = AttributionButtonPosition.BottomRight,
  }) : super(
    key: key,
    styleString: "mapbox://styles/mapbox/light-v10",
    // TODO: Pass this access token by environment
    accessToken: "pk.eyJ1Ijoic25ybXR0aHMiLCJhIjoiY2w0ZWVlcWt5MDAwZjNjbW5nMHNvN3kwNiJ9.upoSvMqKIFe3V_zPt1KxmA",
    onMapCreated: onMapCreated,
    onStyleLoadedCallback: onStyleLoaded,
    attributionButtonPosition: AttributionButtonPosition.BottomRight,
    initialCameraPosition: initialCameraPosition,
  );
}