import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routingNew/services/routing.dart';
import 'package:priobike/routingNew/services/mapcontroller.dart';
import 'package:priobike/routingNew/views/widgets/lastSearchRequests.dart';
import 'package:priobike/routingNew/views/widgets/selectOnMap.dart';
import 'package:priobike/routingNew/views/widgets/selectOnMapButton.dart';
import 'package:priobike/routingNew/views/widgets/searchBar.dart';
import 'package:priobike/routingNew/views/widgets/shortcuts.dart';
import 'package:priobike/routingNew/views/widgets/waypointListItemView.dart';
import 'package:provider/provider.dart';

import 'widgets/currentLocationButton.dart';

class SearchView extends StatefulWidget {
  final int? index;
  final Function onPressed;
  final bool fromRouteSearch;

  const SearchView({Key? key, this.index, required this.onPressed, required this.fromRouteSearch}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SearchViewState();
}

class SearchViewState extends State<SearchView> {
  /// The associated geosearch service, which is injected by the provider.
  late Geosearch geosearch;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts shortcuts;

  /// The associated position service, which is injected by the provider.
  late Positioning positioning;

  /// The associated mapController service, which is injected by the provider.
  late MapController mapController;

  /// The associated profile service, which is injected by the provider.
  late Profile profile;

  /// The Location Search Text Editing Controller
  final TextEditingController _locationSearchController = TextEditingController();

  /// The currentLocationWaypoint
  Waypoint? currentLocationWaypoint;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    routing = Provider.of<Routing>(context);
    shortcuts = Provider.of<Shortcuts>(context);
    mapController = Provider.of<MapController>(context);
    profile = Provider.of<Profile>(context);
    positioning = Provider.of<Positioning>(context);
    geosearch = Provider.of<Geosearch>(context);
    // to update the position of the current Location Waypoint
    updateWaypoint();

    super.didChangeDependencies();
  }

  /// Update the waypoint.
  updateWaypoint() {
    if (positioning.lastPosition == null) {
      currentLocationWaypoint = null;
      return;
    }
    if (currentLocationWaypoint != null &&
        currentLocationWaypoint!.lat == positioning.lastPosition!.latitude &&
        currentLocationWaypoint!.lon == positioning.lastPosition!.longitude) {
      return;
    }
    currentLocationWaypoint = Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude);
  }

  /// A callback that is fired when a waypoint is tapped.
  Future<void> onWaypointTapped(Waypoint waypoint) async {
    geosearch.clearGeosearch();
    final waypoints = routing.selectedWaypoints ?? [];
    // exchange with new waypoint
    List<Waypoint> newWaypoints = waypoints.toList();
    List<Waypoint?> newRoutingItems = routing.routingItems;
    if (widget.index != null) {
      // Check if it has to be put in selectedWaypoints or not.
      if (widget.fromRouteSearch) {
        newRoutingItems[widget.index!] = waypoint;
        await routing.selectRoutingItems(newRoutingItems);
      } else {
        newWaypoints[widget.index!] = waypoint;
      }
    } else {
      // Insert current location as first waypoint if option is set
      if (profile.setLocationAsStart &&
          currentLocationWaypoint != null &&
          waypoints.isEmpty &&
          waypoint.address != null) {
        newWaypoints = [currentLocationWaypoint!, waypoint];
      } else {
        newWaypoints = [...waypoints, waypoint];
      }
    }

    // Save in search history.
    if (waypoint.address != null && profile.saveSearchHistory) {
      profile.saveNewSearch(waypoint);
    }

    // Only set waypoints when not from routeSearchView.
    if (!widget.fromRouteSearch) {
      await routing.selectWaypoints(newWaypoints);
    }

    Navigator.of(context).pop(waypoint);
  }

  /// A callback that is fired when a waypoint is tapped.
  void onCompleteSearch(Waypoint waypoint) {
    setState(() {
      if (waypoint.address != null) {
        _locationSearchController.text = waypoint.address!;
      }
      geosearch.geosearch(context, _locationSearchController.text);
    });
  }

  /// The callback that is executed when the select on map button is pressed.
  _selectOnMapOnPressed() async {
    // Closing the keyboard. Otherwise the inputs for the map are kind of laggy.
    FocusManager.instance.primaryFocus?.unfocus();
    // We have to wait a little while since we can't await the void method above.
    await Future.delayed(const Duration(milliseconds: 100));
    final waypoint = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SelectOnMapView(withName: false),
      ),
    );

    final waypoints = routing.selectedWaypoints ?? [];
    // exchange with new waypoint
    List<Waypoint> newWaypoints = waypoints.toList();

    if (!widget.fromRouteSearch) {
      if (widget.index != null) {
        newWaypoints[widget.index!] = waypoint;
      } else {
        // Insert current location as first waypoint if option is set
        if (profile.setLocationAsStart &&
            currentLocationWaypoint != null &&
            waypoints.isEmpty &&
            waypoint.address != null) {
          newWaypoints = [currentLocationWaypoint!, waypoint];
        } else {
          newWaypoints = [...waypoints, waypoint];
        }
      }
    }

    await routing.selectWaypoints(newWaypoints);

    Navigator.of(context).pop(waypoint);
  }

  /// The callback that is executed when the current location button is pressed.
  _currentLocationPressed() async {
    if (currentLocationWaypoint != null) {
      Navigator.of(context).pop(currentLocationWaypoint);
    }
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Stack(children: [
          // Top Bar
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                color: Brightness.light == Theme.of(context).brightness
                    ? Theme.of(context).colorScheme.background
                    : Theme.of(context).scaffoldBackgroundColor,
                child: SafeArea(
                  top: true,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      children: [
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Hero(
                            tag: 'appBackButton',
                            child: AppBackButton(
                                icon: Icons.chevron_left_rounded,
                                onPressed: () {
                                  geosearch.clearGeosearch();
                                  Navigator.pop(context);
                                },
                                elevation: 5),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            // Avoid expansion of alerts view.
                            width: frame.size.width - 80,
                            child: SearchBar(
                                fromClicked: true,
                                startSearch: () {},
                                locationSearchController: _locationSearchController),
                          ),
                        ]),
                        ShortCutsRow(onPressed: widget.onPressed, close: true),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(0),
                  children: [
                    Container(
                      width: frame.size.width,
                      height: 10,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    (widget.index == null && widget.fromRouteSearch) || (widget.index != null && widget.index! == 0)
                        ? CurrentLocationButton(onPressed: _currentLocationPressed)
                        : Container(),
                    SelectOnMapButton(onPressed: _selectOnMapOnPressed),
                    _locationSearchController.text == ""
                        ? LastSearchRequests(
                            onCompleteSearch: onCompleteSearch,
                            onWaypointTapped: onWaypointTapped,
                            fromRouteSearch: false,
                          )
                        : Container(),
                    Column(children: [
                      const SmallVSpace(),
                      if (geosearch.results?.isNotEmpty == true) ...[
                        for (final waypoint in geosearch.results!) ...[
                          WaypointListItemView(
                            waypoint: waypoint,
                            onTap: onWaypointTapped,
                            onCompleteSearch: onCompleteSearch,
                            fromRouteSearch: false,
                          )
                        ]
                      ]
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
