import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/debouncer.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:provider/provider.dart';

class WaypointListItemView extends StatefulWidget {
  /// If the item is displaying the current position.
  final bool isCurrentPosition;

  /// The associated waypoint.
  final Waypoint? waypoint;

  /// A callback function that is called when the user taps on the item.
  final void Function(Waypoint) onTap;

  const WaypointListItemView({
    this.isCurrentPosition = false,
    required this.waypoint,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => WaypointListItemViewState();
}

class WaypointListItemViewState extends State<WaypointListItemView> {
  /// The associated position service, which is injected by the provider.
  late Positioning positioning;

  /// The associated geosearch service, which is injected by the provider.
  late Geosearch geosearch;

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
    if (positioning.lastPosition == null) return;
    if (widget.waypoint == null) return;
    final lastPos = LatLng(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude);
    final waypointPos = LatLng(widget.waypoint!.lat, widget.waypoint!.lon);
    const vincenty = Distance(roundResult: false);
    distance = vincenty.distance(lastPos, waypointPos);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: ListTile(
        title: widget.waypoint == null
            ? null
            : widget.isCurrentPosition
                ? BoldSubHeader(
                    text: "Aktueller Standort",
                    context: context,
                    color: Colors.white,
                  )
                : BoldSmall(
                    text: widget.waypoint!.address!,
                    context: context,
                    color: widget.isCurrentPosition ? Theme.of(context).colorScheme.onPrimary : null,
                  ),
        subtitle: widget.isCurrentPosition
            ? null
            : (distance == null
                ? null
                : (distance! > 1000
                    ? (Small(text: "${(distance! / 1000).toStringAsFixed(1)} km entfernt", context: context))
                    : (Small(text: "${distance!.toStringAsFixed(0)} m entfernt", context: context)))),
        trailing: widget.waypoint == null
            ? CircularProgressIndicator(
                color: Theme.of(context).colorScheme.onPrimary,
              )
            : Icon(
                widget.isCurrentPosition ? Icons.location_on : Icons.arrow_forward,
                color: widget.isCurrentPosition ? Colors.white : Theme.of(context).colorScheme.primary,
              ),
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

class CurrentPositionWaypointListItemView extends StatefulWidget {
  /// A callback function that is called when the user taps on the item.
  final void Function(Waypoint) onTap;

  const CurrentPositionWaypointListItemView({required this.onTap, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CurrentPositionWaypointListItemViewState();
}

class CurrentPositionWaypointListItemViewState extends State<CurrentPositionWaypointListItemView> {
  /// The associated position service, which is injected by the provider.
  late Positioning positioning;

  /// The currently fetched address.
  Waypoint? waypoint;

  @override
  void didChangeDependencies() {
    positioning = Provider.of<Positioning>(context);
    updateWaypoint();
    super.didChangeDependencies();
  }

  /// Update the waypoint.
  void updateWaypoint() {
    if (positioning.lastPosition == null) {
      waypoint = null;
      return;
    }
    if (waypoint != null &&
        waypoint!.lat == positioning.lastPosition!.latitude &&
        waypoint!.lon == positioning.lastPosition!.longitude) return;
    waypoint = Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return WaypointListItemView(
      isCurrentPosition: true,
      waypoint: waypoint,
      onTap: widget.onTap,
    );
  }
}

/// A search page for waypoints.
class RouteSearch extends StatefulWidget {
  /// A bool which can be set by the parent widget to determine whether the
  /// current user position should be a suggested waypoint.
  final bool showCurrentPositionAsWaypoint;

  const RouteSearch({Key? key, required this.showCurrentPositionAsWaypoint}) : super(key: key);

  @override
  RouteSearchState createState() => RouteSearchState();
}

class RouteSearchState extends State<RouteSearch> {
  /// The geosearch service that is injected by the provider.
  late Geosearch geosearch;

  /// The positioning service that is injected by the provider.
  late Positioning positioning;

  /// The debouncer for the search.
  final debouncer = Debouncer(milliseconds: 100);

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback(
      (_) async {
        await positioning.requestSingleLocation(context);
      },
    );
  }

  @override
  void didChangeDependencies() {
    geosearch = Provider.of<Geosearch>(context);
    positioning = Provider.of<Positioning>(context);
    super.didChangeDependencies();
  }

  /// A callback that is fired when the search is updated.
  Future<void> onSearchUpdated(String? query) async {
    if (query == null) return;
    debouncer.run(
      () {
        geosearch.geosearch(context, query);
      },
    );
  }

  /// A callback that is fired when a waypoint is tapped.
  Future<void> onWaypointTapped(Waypoint waypoint) async {
    Navigator.of(context).pop(waypoint);
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: frame.padding.top),
            color: Theme.of(context).colorScheme.background,
            child: Row(
              children: [
                AppBackButton(onPressed: () => Navigator.pop(context)),
                const SmallHSpace(),
                Container(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  width: frame.size.width - 72,
                  child: TextField(
                    autofocus: true,
                    onChanged: onSearchUpdated,
                    decoration: InputDecoration(
                      hintText: "Suche",
                      border: const OutlineInputBorder(
                          borderRadius:
                              BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24))),
                      suffixIcon: geosearch.isFetchingAddress
                          ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
                          : const Icon(Icons.search),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SmallVSpace(),
                  if (positioning.lastPosition != null && widget.showCurrentPositionAsWaypoint)
                    CurrentPositionWaypointListItemView(onTap: onWaypointTapped),
                  if (geosearch.results?.isNotEmpty == true) ...[
                    for (final waypoint in geosearch.results!) ...[
                      WaypointListItemView(waypoint: waypoint, onTap: onWaypointTapped)
                    ]
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Small(text: "Keine weiteren Ergebnisse", context: context),
                    )
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
