import 'dart:async';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routing/services/map_settings.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views_beta/widgets/last_search_requests.dart';
import 'package:priobike/routing/views_beta/widgets/routing_bar.dart';
import 'package:priobike/routing/views_beta/widgets/select_on_map.dart';
import 'package:priobike/routing/views_beta/widgets/select_on_map_button.dart';

import 'widgets/current_location_button.dart';

class RouteSearchView extends StatefulWidget {
  final Function onPressed;

  final StreamController<DraggableScrollableNotification> sheetMovement;

  const RouteSearchView({Key? key, required this.onPressed, required this.sheetMovement}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RouteSearchViewState();
}

class RouteSearchViewState extends State<RouteSearchView> {
  /// The associated geosearch service, which is injected by the provider.
  late Geosearch geosearch;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts shortcuts;

  /// The associated position service, which is injected by the provider.
  late Positioning positioning;

  /// The associated mapController service, which is injected by the provider.
  late MapSettings mapController;

  /// The associated profile service, which is injected by the provider.
  late Profile profile;

  /// The Location Search Text Editing Controller
  final TextEditingController _locationSearchController = TextEditingController();

  /// The currentLocationWaypoint
  Waypoint? currentLocationWaypoint;

  /// Called when a listener callback of a ChangeNotifier is fired.
  late VoidCallback update;

  /// The singleton instance of our dependency injection service.
  final getIt = GetIt.instance;

  @override
  void initState() {
    super.initState();

    update = () {
      // to update the position of the current Location Waypoint
      updateWaypoint();
      setState(() {});
    };

    routing = getIt.get<Routing>();
    routing.addListener(update);
    shortcuts = getIt.get<Shortcuts>();
    shortcuts.addListener(update);
    profile = getIt.get<Profile>();
    profile.addListener(update);
    positioning = getIt.get<Positioning>();
    positioning.addListener(update);
    mapController = getIt.get<MapSettings>();
    mapController.addListener(update);
    geosearch = getIt.get<Geosearch>();
    geosearch.addListener(update);

    // to update the position of the current Location Waypoint
    updateWaypoint();
  }

  @override
  void dispose() {
    routing.removeListener(update);
    shortcuts.removeListener(update);
    profile.removeListener(update);
    positioning.removeListener(update);
    mapController.removeListener(update);
    geosearch.removeListener(update);
    super.dispose();
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
    if (routing.nextItem >= 0) {
      routing.routingItems[routing.nextItem] = waypoint;
      routing.notifyListeners();
    }
    checkNextItem();
  }

  /// A callback that is fired when a waypoint is tapped.
  void onCompleteSearch(Waypoint waypoint) {
    setState(() {
      if (waypoint.address != null) {
        _locationSearchController.text = waypoint.address!;
      }
      geosearch.geosearch(_locationSearchController.text);
    });
  }

  /// The callback that is executed when the select on map button is pressed.
  _selectOnMapOnPressed() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SelectOnMapView(withName: false),
      ),
    );
    if (routing.nextItem >= 0 && result != null) {
      routing.routingItems[routing.nextItem] = result;
      routing.notifyListeners();
    }
    checkNextItem();
  }

  /// The callback that is executed when the current location button is pressed.
  _currentLocationPressed() async {
    if (currentLocationWaypoint != null) {
      routing.routingItems[routing.nextItem] = currentLocationWaypoint;
      routing.notifyListeners();
    }
    checkNextItem();
  }

  /// A Function which finds the next missing item or reroutes to previous the screen.
  checkNextItem() async {
    if (routing.routingItems.isEmpty) return;

    int nextItemIndex = -1;
    for (int i = 0; i < routing.routingItems.length; i++) {
      if (routing.routingItems[i] == null && nextItemIndex == -1) {
        nextItemIndex = i;
      }
    }
    if (nextItemIndex == -1) {
      // Return to map view.
      // Cast checked in loop.
      await routing.selectWaypoints(routing.routingItems.map((e) => e!).toList());
      routing.routingItems = [];
      routing.nextItem = -1;
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      routing.nextItem = nextItemIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            RoutingBar(
              fromRoutingSearch: true,
              checkNextItem: checkNextItem,
              onPressed: widget.onPressed,
              sheetMovement: widget.sheetMovement,
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
                  CurrentLocationButton(onPressed: _currentLocationPressed),
                  SelectOnMapButton(onPressed: _selectOnMapOnPressed),
                  _locationSearchController.text == ""
                      ? LastSearchRequests(
                          onCompleteSearch: onCompleteSearch, onWaypointTapped: onWaypointTapped, fromRouteSearch: true)
                      : Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
