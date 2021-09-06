import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/config/config.dart';

class MapPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MapPageState();
  }
}

class _MapPageState extends State<MapPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black.withOpacity(0),
          body: MapboxMap(
            accessToken: Config.MAPBOX_API_TOKEN,
            initialCameraPosition: CameraPosition(
              target: LatLng(51.050, 13.737),
              zoom: 11.0,
            ),
            styleString: MapboxStyles.DARK,
            myLocationEnabled: false,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              color: Colors.black.withOpacity(0),
            ),
          ),
        ),
      ],
    );
  }
}
