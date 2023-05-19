import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/debouncer.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/positioning/views/location_access_denied_dialog.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/geosearch.dart';

class WaypointListItemView extends StatefulWidget {
  /// If the item is displaying the current position.
  final bool isCurrentPosition;

  /// The associated waypoint.
  final Waypoint waypoint;

  /// If the history icon should be shown.
  final bool showHistoryIcon;

  /// The distance to the waypoint in meters.
  final double? distance;

  const WaypointListItemView({
    this.isCurrentPosition = false,
    this.distance,
    required this.waypoint,
    required this.showHistoryIcon,
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

  /// If the delete icon should be displayed.
  late bool showDeleteIcon;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    geosearch = getIt<Geosearch>();
    geosearch.addListener(update);
    positioning = getIt<Positioning>();
    positioning.addListener(update);
    showDeleteIcon = false;
  }

  @override
  void dispose() {
    geosearch.removeListener(update);
    positioning.removeListener(update);
    super.dispose();
  }

  /// A callback that is fired when a history item is long pressed.
  Future<void> temporarilyShowDeleteIcon(Waypoint waypoint) async {
    // Long press is only available for history items, not search results.
    if (widget.showHistoryIcon == false) return;
    showDeleteIcon = true;
    setState(() {});

    // Hide icon again after 5 seconds.
    await Future.delayed(const Duration(milliseconds: 5000));
    showDeleteIcon = false;
    setState(() {});
  }

  /// A callback that is fired when a waypoint is tapped.
  Future<void> tappedWaypoint(Waypoint waypoint) async {
    /// The current position is not saved in the search history.
    if (!widget.isCurrentPosition) await geosearch.addToSearchHistory(waypoint);
    geosearch.clearGeosearch();
  }

  /// Delete a waypoint from the search history.
  Future<void> deleteWaypointFromHistory(Waypoint waypoint) async {
    await geosearch.removeItemFromSearchHistory(waypoint);
    showDeleteIcon = false;
    setState(() {});
  }

  /// Generic function to render history items, search results and current position.
  Widget renderItem() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 12),
      child: ListTile(
        leading: widget.showHistoryIcon
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.history,
                  ),
                ],
              )
            : null,
        title: widget.isCurrentPosition
            ? BoldSubHeader(
                text: "Aktueller Standort",
                context: context,
                color: Colors.white,
              )
            : BoldSmall(
                text: widget.waypoint.address!,
                context: context,
                color: Theme.of(context).colorScheme.onBackground,
              ),
        subtitle: widget.isCurrentPosition
            ? null
            : (widget.distance == null)
                ? null
                : (widget.distance! >= 1000)
                    ? (Small(text: "${(widget.distance! / 1000).toStringAsFixed(1)} km entfernt", context: context))
                    : (Small(text: "${widget.distance!.toStringAsFixed(0)} m entfernt", context: context)),
        trailing: (showDeleteIcon == true && widget.showHistoryIcon == true && widget.isCurrentPosition == false)
            // if trying to delete item
            ? IconButton(
                onPressed: () {
                  deleteWaypointFromHistory(widget.waypoint);
                },
                icon: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            // if ready to use item (default)
            : Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  widget.isCurrentPosition ? Icons.location_on : Icons.arrow_forward,
                  color: widget.isCurrentPosition ? Colors.white : Theme.of(context).colorScheme.primary,
                ),
              ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        tileColor:
            widget.isCurrentPosition ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.background,
        onTap: () {
          tappedWaypoint(widget.waypoint);
          Navigator.of(context).pop(widget.waypoint);
        },
        onLongPress: () {
          temporarilyShowDeleteIcon(widget.waypoint);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't show history items if the user is already there
    if (widget.showHistoryIcon == true && widget.distance != null && widget.distance! <= 10) return Container();

    // If item is a history item, wrap it with dismissible
    // If item is search result, just render it
    return (widget.showHistoryIcon == true)
        ? Dismissible(
            key: Key(widget.waypoint.hashCode.toString()),
            onDismissed: (direction) {
              deleteWaypointFromHistory(widget.waypoint);
              ToastMessage.showSuccess("Eintrag gelöscht");
            },
            direction: DismissDirection.endToStart,
            background: Container(color: Theme.of(context).colorScheme.primary),
            child: renderItem(),
          )
        : renderItem();
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

  /// The current search query in the search field.
  String searchQuery = "";

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        await positioning.requestSingleLocation(
          onNoPermission: () {
            Navigator.of(context).pop();
            showLocationAccessDeniedDialog(context, positioning.positionSource);
          },
        );
      },
    );

    geosearch = getIt<Geosearch>();
    geosearch.addListener(update);
    positioning = getIt<Positioning>();
    positioning.addListener(update);
    geosearch.loadSearchHistory();
    geosearch.clearGeosearch();
  }

  @override
  void dispose() {
    geosearch.removeListener(update);
    positioning.removeListener(update);
    super.dispose();
  }

  /// A callback that is fired when the search is updated.
  Future<void> onSearchUpdated(String? query) async {
    if (query == null) return;
    searchQuery = query;
    debouncer.run(
      () {
        geosearch.geosearch(searchQuery);
      },
    );
  }

  /// Calculate distance to the user for each waypoint and optionally sorts the results in ascending order.
  /// Returns map with waypoint as key and distance as value.
  Map<Waypoint, double?> calculateDistanceToWaypoints(
      {required List<Waypoint> waypoints, required bool sortByDistance}) {
    if (positioning.lastPosition == null) return waypoints.asMap().map((key, value) => MapEntry(value, null));

    final lastPos = LatLng(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude);
    var dictionary = <Waypoint, double>{};
    for (final waypoint in waypoints) {
      final waypointPos = LatLng(waypoint.lat, waypoint.lon);
      const vincenty = Distance(roundResult: false);
      final distance = vincenty.distance(lastPos, waypointPos);
      dictionary[waypoint] = distance;
    }

    if (sortByDistance) {
      return Map.fromEntries(dictionary.entries.toList()..sort((e1, e2) => e1.value.compareTo(e2.value)));
    }
    return dictionary;
  }

  /// Ask the user for confirmation if he wants to delete all waypoints from the search history.
  Future<void> deleteWholeSearchHistoryDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Gesamten Suchverlauf löschen"),
          content: const Text("Möchtest du den Suchverlauf wirklich löschen?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Abbrechen"),
            ),
            TextButton(
              onPressed: () {
                geosearch.deleteSearchHistory();
                Navigator.of(context).pop();
              },
              child: const Text("Löschen"),
            ),
          ],
        );
      },
    );
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SmallVSpace(),
                  if (positioning.lastPosition != null && widget.showCurrentPositionAsWaypoint)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: WaypointListItemView(
                        isCurrentPosition: true,
                        waypoint: Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude),
                        showHistoryIcon: false,
                      ),
                    ),

                  // Search History (sorted by recency of searches)
                  if (geosearch.searchHistory.isNotEmpty && searchQuery.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 24, top: 4, bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BoldContent(
                            text: "Letzte Suchergebnisse",
                            context: context,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              size: 20,
                            ),
                            onPressed: () {
                              deleteWholeSearchHistoryDialog();
                            },
                          ),
                        ],
                      ),
                    ),
                    for (final entry in calculateDistanceToWaypoints(
                            waypoints: geosearch.searchHistory.reversed.toList(), sortByDistance: false)
                        .entries) ...[
                      WaypointListItemView(
                        waypoint: entry.key,
                        distance: entry.value,
                        showHistoryIcon: true,
                      )
                    ]
                  ],

                  // Search Results (sorted by distance to user)
                  if (geosearch.results?.isNotEmpty == true) ...[
                    for (final entry
                        in calculateDistanceToWaypoints(waypoints: geosearch.results!, sortByDistance: true)
                            .entries) ...[
                      WaypointListItemView(
                        waypoint: entry.key,
                        distance: entry.value,
                        showHistoryIcon: false,
                      )
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: 16, left: 28, bottom: 20),
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
