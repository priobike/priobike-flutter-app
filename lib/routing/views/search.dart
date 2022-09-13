import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/positioning/services/position.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/geocoding.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:provider/provider.dart';

class WaypointListItemView extends StatefulWidget {
  /// If the item is displaying the current position.
  final bool isCurrentPosition;

  /// The associated waypoint.
  final Waypoint waypoint;

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
  PositionService? positionService;

  /// The associated geosearch service, which is injected by the provider.
  GeosearchService? geosearchService;

  /// The distance to the waypoint in meters.
  double? distance;

  @override
  void didChangeDependencies() {
    geosearchService = Provider.of<GeosearchService>(context);
    positionService = Provider.of<PositionService>(context);

    // Update the distance to the waypoint.
    updateDistance();

    super.didChangeDependencies();
  }

  /// Update the distance to the waypoint.
  void updateDistance() {
    if (positionService?.lastPosition == null) return;
    final lastPos = LatLng(positionService!.lastPosition!.latitude, positionService!.lastPosition!.longitude);
    final waypointPos = LatLng(widget.waypoint.lat, widget.waypoint.lon);
    const vincenty = Distance();
    final distance = vincenty.distance(lastPos, waypointPos);
    setState(() => this.distance = distance);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: ListTile(
        title: BoldSmall(
          text: widget.waypoint.address, 
          context: context,
          color: widget.isCurrentPosition ? Theme.of(context).colorScheme.onPrimary : null,
        ),
        subtitle: widget.isCurrentPosition 
          ? Small(text: "Aktuelle Position", context: context, color: Theme.of(context).colorScheme.onPrimary)
          : (
            distance == null ? null : (
              distance! > 1000 ? (
                Small(text: "${(distance! / 1000).toStringAsFixed(1)} km entfernt", context: context)
              ) : (
                Small(text: "${distance!.toStringAsFixed(0)} m entfernt", context: context)
              )
            )
          ),
        trailing: Icon(
          widget.isCurrentPosition ?
            Icons.location_on :
            Icons.arrow_forward, 
          color: widget.isCurrentPosition 
           ? Theme.of(context).colorScheme.onPrimary
           : Theme.of(context).colorScheme.primary,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24))
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        tileColor: widget.isCurrentPosition 
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.background,
        onTap: () => widget.onTap(widget.waypoint),
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
  PositionService? positionService;

  /// The currently fetched address.
  Waypoint? waypoint;

  @override
  void didChangeDependencies() {
    positionService = Provider.of<PositionService>(context);
    updateWaypoint();
    super.didChangeDependencies();
  }

  /// Update the waypoint.
  Future<void> updateWaypoint() async {
    if (positionService?.lastPosition == null) {
      setState(() => waypoint = null);
      return;
    }
    if (
      waypoint != null && 
      waypoint!.lat == positionService!.lastPosition!.latitude && 
      waypoint!.lon == positionService!.lastPosition!.longitude
    ) return;
    final geocodingService = Provider.of<GeocodingService>(context, listen: false);
    final pos = positionService!.lastPosition!;
    final address = await geocodingService.reverseGeocodeLatLng(context, pos.latitude, pos.longitude);
    if (address == null) return;
    setState(() => waypoint = Waypoint(pos.latitude, pos.longitude, address: address));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: waypoint == null
        ? Container()
        : WaypointListItemView(
          isCurrentPosition: true,
          waypoint: waypoint!, 
          onTap: widget.onTap
        )
    );
  }
}

class Debouncer {
  /// The preferred interval.
  final int milliseconds;

  /// The currently running timer.
  Timer? timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    timer?.cancel();
    timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

/// A search page for waypoints.
class RouteSearch extends StatefulWidget {
  const RouteSearch({Key? key}) : super(key: key);

  @override
  RouteSearchState createState() => RouteSearchState();
}

class RouteSearchState extends State<RouteSearch> {
  /// The geosearch service that is injected by the provider.
  late GeosearchService geosearchService;

  /// The positioning service that is injected by the provider.
  late PositionService positionService;

  /// The debouncer for the search.
  final debouncer = Debouncer(milliseconds: 100);

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      await positionService.requestSingleLocation(context);
    });
  }

  @override
  void didChangeDependencies() {
    geosearchService = Provider.of<GeosearchService>(context);
    positionService = Provider.of<PositionService>(context);
    super.didChangeDependencies();
  }

  /// A callback that is fired when the search is updated.
  Future<void> onSearchUpdated(String? query) async {
    if (query == null) return;
    debouncer.run(() {
      geosearchService.geosearch(context, query);
    });
  }

  /// A callback that is fired when a waypoint is tapped.
  Future<void> onWaypointTapped(Waypoint waypoint) async {
    Navigator.of(context).pop(waypoint);
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    return Scaffold(body:
      Column(children: [
        Container(
          padding: EdgeInsets.only(top: frame.padding.top),
          color: Theme.of(context).colorScheme.background,
          child: Row(children: [
            AppBackButton(icon: Icons.chevron_left, onPressed: () => Navigator.pop(context)),
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
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24), 
                      bottomLeft: Radius.circular(24)
                    )
                  ),
                  suffixIcon: geosearchService.isFetchingAddress 
                    ? const Padding(
                        padding: EdgeInsets.all(12), 
                        child: CircularProgressIndicator()
                      )
                    : const Icon(Icons.search),
                ),
              ),
            ),
          ]),
        ),
        Expanded(child: SingleChildScrollView(
          child: Column(children: [
            const SmallVSpace(),
            if (positionService.lastPosition != null)
              CurrentPositionWaypointListItemView(onTap: onWaypointTapped),
            if (geosearchService.results?.isNotEmpty == true) ...[
              for (final waypoint in geosearchService.results!) ...[
                WaypointListItemView(waypoint: waypoint, onTap: onWaypointTapped)
              ]
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Small(text: "Keine Ergebnisse", context: context),
              )
            ],
          ])
        )),
      ]),
    );
  }
}