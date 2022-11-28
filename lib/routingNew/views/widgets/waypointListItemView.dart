import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class WaypointListItemView extends StatefulWidget {
  /// If the item is displaying the current position.
  final bool isCurrentPosition;

  /// The associated waypoint.
  final Waypoint? waypoint;

  /// A callback function that is called when the user taps on the item.
  final void Function(Waypoint) onTap;

  /// A callback function that is called when the user taps on the ArrowButton.
  final void Function(Waypoint) onCompleteSearch;

  final bool fromRouteSearch;

  const WaypointListItemView({
    this.isCurrentPosition = false,
    this.waypoint,
    required this.onTap,
    required this.onCompleteSearch,
    required this.fromRouteSearch,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => WaypointListItemViewState();
}

class WaypointListItemViewState extends State<WaypointListItemView> {
  /// The associated position service, which is injected by the provider.
  Positioning? positioning;

  /// The associated geosearch service, which is injected by the provider.
  Geosearch? geosearch;

  /// The distance to the waypoint in meters.
  double? distance;

  @override
  void didChangeDependencies() {
    geosearch = Provider.of<Geosearch>(context);
    positioning = Provider.of<Positioning>(context);

    // Update the distance to the waypoint.
    updateDistance();

    super.didChangeDependencies();
  }

  /// Update the distance to the waypoint.
  void updateDistance() {
    if (positioning?.lastPosition == null) return;
    if (widget.waypoint == null) return;
    final lastPos = LatLng(positioning!.lastPosition!.latitude, positioning!.lastPosition!.longitude);
    final waypointPos = LatLng(widget.waypoint!.lat, widget.waypoint!.lon);
    const vincenty = Distance();
    distance = vincenty.distance(lastPos, waypointPos);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: ListTile(
        leading: widget.waypoint == null
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on),
                  widget.isCurrentPosition
                      ? Small(
                          text: "Aktuelle Position", context: context, color: Theme.of(context).colorScheme.onPrimary)
                      : (distance == null
                          ? Container()
                          : (distance! > 1000
                              ? (Small(text: "${(distance! / 1000).toStringAsFixed(1)} km", context: context))
                              : (Small(text: "${distance!.toStringAsFixed(0)} m", context: context)))),
                ],
              ),
        title: widget.waypoint == null
            ? null
            : BoldSmall(
                text: widget.waypoint!.address ?? "",
                context: context,
                color: widget.isCurrentPosition ? Theme.of(context).colorScheme.onPrimary : null,
              ),
        trailing: !widget.fromRouteSearch ? IconButton(
          icon: Transform.rotate(
            angle: -45 * math.pi / 180,
            child: Icon(
              Icons.arrow_upward_sharp,
              color: Theme.of(context).colorScheme.brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          onPressed: () {
            if (widget.waypoint != null) {
              widget.onCompleteSearch(widget.waypoint!);
            }
          },
          splashRadius: 20,
        ) : null,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        tileColor:
            widget.isCurrentPosition ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.background,
        onTap: () {
          if (widget.waypoint != null) widget.onTap(widget.waypoint!);
        },
      ),
    );
  }
}
