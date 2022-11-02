import 'package:flutter/material.dart';

/// An alert icon.
class AlertIcon extends Image {
  const AlertIcon({double width = 24, double height = 24, Key? key})
      : super(
          key: key,
          image: const AssetImage("assets/images/alert.drawio.png"),
          width: width,
          height: height,
          color: null,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        );
}

class BadSignalIcon extends Image {
  const BadSignalIcon({double width = 24, double height = 24, Key? key})
      : super(
          key: key,
          image: const AssetImage("assets/images/bad-signal.drawio.png"),
          width: width,
          height: height,
          color: null,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        );
}

class DisconnectedIcon extends Image {
  const DisconnectedIcon({double width = 24, double height = 24, Key? key})
      : super(
          key: key,
          image: const AssetImage("assets/images/disconnected.drawio.png"),
          width: width,
          height: height,
          color: null,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        );
}

class OfflineIcon extends Image {
  const OfflineIcon({double width = 24, double height = 24, Key? key})
      : super(
          key: key,
          image: const AssetImage("assets/images/offline.drawio.png"),
          width: width,
          height: height,
          color: null,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        );
}

/// A start icon.
class StartIcon extends Image {
  const StartIcon({double width = 24, double height = 24, Key? key})
      : super(
          key: key,
          image: const AssetImage("assets/images/start.drawio.png"),
          width: width,
          height: height,
          color: null,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        );
}

/// A destination icon.
class DestinationIcon extends Image {
  const DestinationIcon({double width = 24, double height = 24, Key? key})
      : super(
          key: key,
          image: const AssetImage("assets/images/destination.drawio.png"),
          width: width,
          height: height,
          color: null,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        );
}

/// A waypoint icon.
class WaypointIcon extends Image {
  const WaypointIcon({double width = 24, double height = 24, Key? key})
      : super(
          key: key,
          image: const AssetImage("assets/images/waypoint.drawio.png"),
          width: width,
          height: height,
          color: null,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        );
}
