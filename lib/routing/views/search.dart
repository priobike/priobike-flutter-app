import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/debouncer.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/positioning/views/location_access_denied_dialog.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaypointListItemView extends StatefulWidget {
  /// If the item is displaying the current position.
  final bool isCurrentPosition;

  /// The associated waypoint.
  final Waypoint? waypoint;

  /// A callback function that is called when the user taps on the item.
  final void Function(Waypoint) onTap;

  /// If the history icon should be shown.
  final bool? showHistoryIcon;

  const WaypointListItemView({
    this.isCurrentPosition = false,
    required this.waypoint,
    required this.onTap,
    this.showHistoryIcon,
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

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    // Update the distance to the waypoint.
    updateDistance();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    geosearch = getIt<Geosearch>();
    geosearch.addListener(update);
    positioning = getIt<Positioning>();
    positioning.addListener(update);

    updateDistance();
  }

  @override
  void dispose() {
    geosearch.removeListener(update);
    positioning.removeListener(update);
    super.dispose();
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
        leading: (widget.showHistoryIcon == null) || (!widget.showHistoryIcon!)
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.history,
                  ),
                ],
              ),
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
                    color: Theme.of(context).colorScheme.onBackground,
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

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    // Update the distance to the waypoint.
    updateWaypoint();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    positioning = getIt<Positioning>();
    positioning.addListener(update);

    // Update the distance to the waypoint.
    updateWaypoint();
  }

  @override
  void dispose() {
    positioning.removeListener(update);
    super.dispose();
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

  /// The last search queries.
  List<Waypoint> searchHistory = [];

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
    initializeSearchHistory();
    // Don't show old search results
    geosearch.results?.clear();
  }

  @override
  void dispose() {
    geosearch.removeListener(update);
    positioning.removeListener(update);
    saveSearchHistory();
    super.dispose();
  }

  /// Initialize the search history from the shared preferences by decoding it from a String List.
  Future<void> initializeSearchHistory() async {
    final preferences = await SharedPreferences.getInstance();
    List<String> tempList = preferences.getStringList("priobike.routing.searchHistory") ?? [];
    searchHistory = [];
    for (String waypoint in tempList) {
      searchHistory.add(Waypoint.fromJson(json.decode(waypoint)));
    }
    setState(() {});
  }

  /// Save the search history to the shared preferences by encoding it as a String List.
  Future<void> saveSearchHistory() async {
    if (searchHistory.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    List<String> tempList = [];
    for (Waypoint waypoint in searchHistory) {
      tempList.add(json.encode(waypoint.toJSON()));
    }
    await preferences.setStringList("priobike.routing.searchHistory", tempList);
    setState(() {});
  }

  /// Add a waypoint to the search history.
  void addToSearchHistory(Waypoint waypoint) {
    // Remove the waypoint from the history if it already exists.
    if (searchHistory.any((element) => element.address == waypoint.address)) {
      searchHistory.removeWhere((element) => element.address == waypoint.address);
    }

    // Only keep the last 10 searches.
    if (searchHistory.length > 10) searchHistory.removeAt(0);

    searchHistory.add(waypoint);
    setState(() {});
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

  /// A callback that is fired when a history item is tapped.
  void onHistoryItemTapped(Waypoint waypoint) {
    geosearch.results?.clear();
    Navigator.of(context).pop(waypoint);
  }

  /// A callback that is fired when a waypoint is tapped.
  void onWaypointTapped(Waypoint waypoint) {
    addToSearchHistory(waypoint);
    geosearch.results?.clear();
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SmallVSpace(),
                  if (positioning.lastPosition != null && widget.showCurrentPositionAsWaypoint)
                    CurrentPositionWaypointListItemView(onTap: onWaypointTapped),

                  // Search History
                  if (searchHistory.isNotEmpty && searchQuery.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 16),
                      child: BoldContent(
                        text: "Letzte Suchergebnisse",
                        context: context,
                      ),
                    ),
                    for (final waypoint in searchHistory.reversed) ...[
                      WaypointListItemView(
                        waypoint: waypoint,
                        onTap: onHistoryItemTapped,
                        showHistoryIcon: true,
                      )
                    ]
                  ],

                  // Search Results
                  if (geosearch.results?.isNotEmpty == true) ...[
                    for (final waypoint in geosearch.results!) ...[
                      WaypointListItemView(
                        waypoint: waypoint,
                        onTap: onWaypointTapped,
                      )
                    ],
                  ],
                  Padding(
                    padding: const EdgeInsets.only(left: 26, bottom: 26),
                    child: Small(text: "Keine weiteren Ergebnisse", context: context),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
