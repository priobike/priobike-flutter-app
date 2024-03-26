import 'package:flutter/material.dart';

/// An alert icon.
class AlertIcon extends Image {
  const AlertIcon({double super.width = 24, double super.height = 24, super.key})
      : super(
          image: const AssetImage("assets/images/alert.drawio.png"),
          color: null,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        );
}

/// A start icon.
class StartIcon extends Image {
  const StartIcon({double super.width = 24, double super.height = 24, super.key})
      : super(
          image: const AssetImage("assets/images/start.drawio.png"),
          color: null,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        );
}

/// A destination icon.
class DestinationIcon extends Image {
  const DestinationIcon({double super.width = 24, double super.height = 24, super.key})
      : super(
          image: const AssetImage("assets/images/destination.drawio.png"),
          color: null,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        );
}

/// A waypoint icon.
class WaypointIcon extends Image {
  const WaypointIcon({double super.width = 24, double super.height = 24, super.key})
      : super(
          image: const AssetImage("assets/images/waypoint.drawio.png"),
          color: null,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        );
}

/// An add waypoint icon.
class AddWaypointIcon extends Image {
  const AddWaypointIcon({double super.width = 24, double super.height = 24, super.key})
      : super(
          image: const AssetImage("assets/images/waypoint-plus.drawio.png"),
          color: null,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        );
}

/// A compass icon.
class CompassIcon extends Image {
  CompassIcon({double super.width = 24, double super.height = 24, required BuildContext context, super.key})
      : super(
          image: Theme.of(context).brightness == Brightness.dark
              ? const AssetImage("assets/images/compass-dark.png")
              : const AssetImage("assets/images/compass-light.png"),
          color: null,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        );
}

/// A current position icon withouth shadow.
class CurrentPositionWithoutShadow extends Image {
  CurrentPositionWithoutShadow(
      {double super.width = 24, double super.height = 24, required BuildContext context, super.key})
      : super(
          image: Theme.of(context).brightness == Brightness.dark
              ? const AssetImage("assets/images/marker-wiki-dark.png")
              : const AssetImage("assets/images/marker-wiki-light.png"),
          color: null,
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
        );
}
