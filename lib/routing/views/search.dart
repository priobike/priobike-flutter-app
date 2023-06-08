import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/debouncer.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/positioning/views/location_access_denied_dialog.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/geosearch.dart';

/// Result of a address search query.
class SearchItem extends StatelessWidget {
  /// The waypoint of the search result.
  final Waypoint waypoint;

  /// The distance to the search result.
  final double? distance;

  /// Callback when the search result is tapped.
  final Function onTapped;

  const SearchItem({
    required this.waypoint,
    required this.onTapped,
    this.distance,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (waypoint.address == null) return Container();
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 12),
      child: ListTile(
        title: BoldSmall(
          text: waypoint.address!,
          context: context,
          color: Theme.of(context).colorScheme.onBackground,
        ),
        subtitle: distance == null
            ? null
            : distance! >= 1000
                ? (Small(text: "${(distance! / 1000).toStringAsFixed(1)} km entfernt", context: context))
                : (Small(text: "${distance!.toStringAsFixed(0)} m entfernt", context: context)),
        trailing: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(
            Icons.arrow_forward,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        tileColor: Theme.of(context).colorScheme.background,
        onTap: () => onTapped(waypoint: waypoint, addToHistory: true),
      ),
    );
  }
}

/// Saved Waypoints from the search history.
class HistoryItem extends StatefulWidget {
  /// The saved waypoint.
  final Waypoint waypoint;

  /// The distance to the saved waypoint.
  final double? distance;

  /// Callback when the saved waypoint is tapped.
  final Function onTapped;

  const HistoryItem({
    required this.waypoint,
    required this.onTapped,
    this.distance,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => HistoryItemState();
}

class HistoryItemState extends State<HistoryItem> {
  /// If user long presses the item, show delete icon.
  bool showDeleteIcon = false;

  /// A callback that is fired when a history item is long pressed.
  Future<void> temporarilyShowDeleteIcon(Waypoint waypoint) async {
    setState(() {
      showDeleteIcon = true;
    });

    // Hide icon again after 5 seconds.
    await Future.delayed(const Duration(milliseconds: 5000));
    setState(() {
      showDeleteIcon = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.waypoint.address == null) return Container();
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 12),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.history,
            ),
          ],
        ),
        title: BoldSmall(
          text: widget.waypoint.address!,
          context: context,
          color: Theme.of(context).colorScheme.onBackground,
        ),
        subtitle: widget.distance == null
            ? null
            : (widget.distance! >= 1000)
                ? (Small(text: "${(widget.distance! / 1000).toStringAsFixed(1)} km entfernt", context: context))
                : (Small(text: "${widget.distance!.toStringAsFixed(0)} m entfernt", context: context)),
        trailing: showDeleteIcon == true
            ? IconButton(
                onPressed: () => getIt<Geosearch>().removeItemFromSearchHistory(widget.waypoint),
                icon: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        tileColor: Theme.of(context).colorScheme.background,
        onTap: () => widget.onTapped(waypoint: widget.waypoint, addToHistory: true),
        onLongPress: () => temporarilyShowDeleteIcon(widget.waypoint),
      ),
    );
  }
}

/// The button with the current position.
class CurrentPosition extends StatelessWidget {
  /// Callback when the current position is tapped.
  final Function onTapped;

  const CurrentPosition({
    required this.onTapped,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final positioning = getIt<Positioning>();
    if (positioning.lastPosition == null) return Container();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        title: BoldSubHeader(
          text: "Aktueller Standort",
          context: context,
          color: Colors.white,
        ),
        trailing: const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(
            Icons.location_on,
            color: Colors.white,
          ),
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        tileColor: Theme.of(context).colorScheme.primary,
        onTap: () => onTapped(
            waypoint: Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude),
            addToHistory: false),
      ),
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

  /// The current search query in the search field.
  String searchQuery = "";

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  /// FocusNode for the search text field that is used to check if unfocused is needed.
  FocusNode searchTextFieldFocusNode = FocusNode();

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

  /// A callback that is fired when a waypoint is tapped.
  Future<void> tappedWaypoint({required Waypoint waypoint, required bool addToHistory}) async {
    /// The current position is not saved in the search history.
    if (addToHistory) await geosearch.addToSearchHistory(waypoint);
    geosearch.clearGeosearch();
    if (mounted) Navigator.of(context).pop(waypoint);
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
                AppBackButton(
                  onPressed: () async {
                    // FIXME we should pay attention to release notes if this Flutter bug might be fixed in the future.
                    // Prevents the keyboard to be focused on pop screen. This can cause ugly map effects on Android.
                    if (Platform.isAndroid && searchTextFieldFocusNode.hasFocus) {
                      searchTextFieldFocusNode.unfocus();
                      // Waiting for the keyboard to be fully unfocused before popping the current screen.
                      await Future.delayed(const Duration(milliseconds: 500)).then((value) => Navigator.pop(context));
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                const SmallHSpace(),
                Container(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  width: frame.size.width - 72,
                  child: TextField(
                    autofocus: true,
                    focusNode: searchTextFieldFocusNode,
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
                    Column(
                      children: [
                        CurrentPosition(
                          onTapped: tappedWaypoint,
                        ),
                        const SmallVSpace(),
                      ],
                    ),
                  // Search History (sorted by recency of searches)
                  if (geosearch.searchHistory.isNotEmpty && searchQuery.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 24, top: 8),
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
                            onPressed: () => deleteWholeSearchHistoryDialog(),
                          ),
                        ],
                      ),
                    ),
                    for (final waypointWithDistance in calculateDistanceToWaypoints(
                            waypoints: geosearch.searchHistory.reversed.toList(), sortByDistance: false)
                        .entries)
                      Dismissible(
                        key: Key(waypointWithDistance.key.hashCode.toString()),
                        onDismissed: (direction) {
                          getIt<Geosearch>().removeItemFromSearchHistory(waypointWithDistance.key);
                          ToastMessage.showSuccess("Eintrag gelöscht");
                        },
                        direction: DismissDirection.endToStart,
                        background: Container(color: CI.red),
                        child: HistoryItem(
                          waypoint: waypointWithDistance.key,
                          distance: waypointWithDistance.value,
                          onTapped: tappedWaypoint,
                        ),
                      ),
                  ],

                  // Search Results (sorted by distance to user)
                  if (geosearch.results.isNotEmpty) ...[
                    for (final waypointWithDistance
                        in calculateDistanceToWaypoints(waypoints: geosearch.results, sortByDistance: true).entries)
                      SearchItem(
                        waypoint: waypointWithDistance.key,
                        distance: waypointWithDistance.value,
                        onTapped: tappedWaypoint,
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12, left: 28, bottom: 20),
                      child: Small(text: "Keine weiteren Ergebnisse", context: context),
                    )
                  ],

                  // No results found
                  if (geosearch.results.isEmpty && geosearch.isFetchingAddress == false && searchQuery.isNotEmpty) ...[
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const VSpace(),
                          Icon(Icons.error, color: Theme.of(context).colorScheme.error, size: 48),
                          const VSpace(),
                          BoldSmall(
                            text: "Es konnten leider keine Ziele gefunden werden.",
                            context: context,
                            textAlign: TextAlign.center,
                          ),
                          const SmallVSpace(),
                          Small(
                            text: "Versuche es mit einer anderen Suchanfrage.",
                            context: context,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
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
