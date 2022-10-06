import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/services/mapcontroller.dart';
import 'package:priobike/routing/views/widgets/lastSearchRequests.dart';
import 'package:priobike/routing/views/widgets/routingBar.dart';
import 'package:priobike/routing/views/widgets/selectOnMap.dart';
import 'package:priobike/routing/views/widgets/selectOnMapButton.dart';
import 'package:provider/provider.dart';

import 'widgets/currentLocationButton.dart';

class RouteSearchView extends StatefulWidget {
  const RouteSearchView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RouteSearchViewState();
}

class RouteSearchViewState extends State<RouteSearchView> {
  /// The associated geosearch service, which is injected by the provider.
  late Geosearch geosearch;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts shortcutsService;

  /// The associated position service, which is injected by the provider.
  late Positioning positioning;

  /// The associated shortcuts service, which is injected by the provider.
  late MapController mapControllerService;

  /// The associated shortcuts service, which is injected by the provider.
  late Profile profileService;

  /// The Location Search Text Editing Controller
  final TextEditingController _locationSearchController =
      TextEditingController();

  /// The currentLocationWaypoint
  Waypoint? currentLocationWaypoint;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    routing = Provider.of<Routing>(context);
    shortcutsService = Provider.of<Shortcuts>(context);
    mapControllerService = Provider.of<MapController>(context);
    profileService = Provider.of<Profile>(context);
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
    currentLocationWaypoint = Waypoint(positioning.lastPosition!.latitude,
        positioning.lastPosition!.longitude);
  }

  /// A callback that is fired when a waypoint is tapped.
  Future<void> onWaypointTapped(Waypoint waypoint) async {
    if (routing.nextItem > 0) {
      routing.routingItems[routing.nextItem] = waypoint;
      routing.notifyListeners();
      checkNextItem();
    }
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

  _selectOnMapOnPressed() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SelectOnMapView(),
      ),
    );
    if (routing.nextItem > 0 && result != null) {
      routing.routingItems[routing.nextItem] = result;
      routing.notifyListeners();
      checkNextItem();
    }
  }

  _currentLocationPressed() async {
    if (routing.nextItem > 0 && currentLocationWaypoint != null) {
      routing.routingItems[routing.nextItem] = currentLocationWaypoint;
      routing.notifyListeners();
      checkNextItem();
    }
  }

  /// A Function which finds the next missing item or reroutes to previous screen
  checkNextItem() async {
    int nextItemIndex = -1;
    for (int i = 0; i < routing.routingItems.length; i++) {
      if (routing.routingItems[i] == null && nextItemIndex == -1) {
        nextItemIndex = i;
      }
    }
    if (nextItemIndex == -1) {
      // return to map view
      // cast checked in loop
      await routing.selectWaypoints(routing.routingItems.map((e) => e!).toList());
      routing.routingItems = [];
      routing.nextItem = -1;
      Navigator.of(context).pop();
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
      value: Theme.of(context).brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            RoutingBar(
                fromRoutingSearch: true, checkNextItem: checkNextItem),
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
                          onCompleteSearch: onCompleteSearch,
                          onWaypointTapped: onWaypointTapped)
                      : Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
