

import 'package:flutter/material.dart';

class AlertIcon extends Image {
  const AlertIcon({double width = 24, double height = 24, Key? key}) : super(
    key: key,
    image: const AssetImage("assets/images/alert.drawio.png"),
    width: width,
    height: height,
    color: null,
    fit: BoxFit.scaleDown,
    alignment: Alignment.center,
  );
}

class StartIcon extends Image {
  const StartIcon({double width = 24, double height = 24, Key? key}) : super(
    key: key,
    image: const AssetImage("assets/images/start.drawio.png"),
    width: width,
    height: height,
    color: null,
    fit: BoxFit.scaleDown,
    alignment: Alignment.center,
  );
}

class DestinationIcon extends Image {
  const DestinationIcon({double width = 24, double height = 24, Key? key}) : super(
    key: key,
    image: const AssetImage("assets/images/destination.drawio.png"),
    width: width,
    height: height,
    color: null,
    fit: BoxFit.scaleDown,
    alignment: Alignment.center,
  );
}

class WaypointIcon extends Image {
  const WaypointIcon({double width = 24, double height = 24, Key? key}) : super(
    key: key,
    image: const AssetImage("assets/images/waypoint.drawio.png"),
    width: width,
    height: height,
    color: null,
    fit: BoxFit.scaleDown,
    alignment: Alignment.center,
  );
}