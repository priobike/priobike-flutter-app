import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:priobike/common/layout/buttons.dart';

/// A view that displays alerts in the routing context.
class GPSButton extends StatelessWidget {
  final MyLocationTrackingMode? myLocationTrackingMode;
  final Function gpsCentralization;

  const GPSButton(
      {Key? key, this.myLocationTrackingMode, required this.gpsCentralization})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: const BorderRadius.all(Radius.circular(24.0)),
      child: SmallIconButton(
        icon: myLocationTrackingMode != null &&
                myLocationTrackingMode == MyLocationTrackingMode.Tracking
            ? Icons.gps_fixed
            : Icons.gps_not_fixed,
        color: Theme.of(context).colorScheme.primary,
        onPressed: () => gpsCentralization(),
      ),
    );
  }
}
