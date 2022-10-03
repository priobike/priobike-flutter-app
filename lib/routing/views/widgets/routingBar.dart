import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/search.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:provider/provider.dart';

/// A callback that is executed when the search page is opened.
Future<void> onSearch(BuildContext context, Routing routing, Profile profile,
    Waypoint? currentLocationWaypoint, int? index, bool isFirstElement) async {
  final result = await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SearchView(
          isFirstElement: isFirstElement || (index != null && index == 0)),
    ),
  );

  if (result == null) return;

  final waypoint = result as Waypoint;
  final waypoints = routing.selectedWaypoints ?? [];
  // exchange with new waypoint
  List<Waypoint> newWaypoints = waypoints.toList();
  if (index != null) {
    newWaypoints[index] = waypoint;
  } else {
    // Insert current location as first waypoint if option is set
    if (profile.setLocationAsStart != null &&
        profile.setLocationAsStart! &&
        currentLocationWaypoint != null &&
        waypoints.isEmpty &&
        waypoint.address != null) {
      newWaypoints = [currentLocationWaypoint, waypoint];
    } else {
      newWaypoints = [...waypoints, waypoint];
    }
  }

  if (waypoint.address != null) {
    profile.saveNewSearch(waypoint);
  }

  await routing.selectWaypoints(newWaypoints);
  await routing.loadRoutes(context);
}

/// A view that displays alerts in the routingOLD context.
class RoutingBar extends StatefulWidget {
  final TextEditingController? locationSearchController;
  final bool fromRoutingSearch;

  const RoutingBar(
      {Key? key,
      this.locationSearchController,
      required this.fromRoutingSearch})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingBarState();
}

class RoutingBarState extends State<RoutingBar> {
  /// The geosearch service that is injected by the provider.
  late Geosearch geosearch;

  /// The associated routingOLD service, which is injected by the provider.
  late Routing routingService;

  /// The associated profile service, which is injected by the provider.
  late Profile profile;

  /// The associated position service, which is injected by the provider.
  late Positioning positioning;

  /// The currently fetched address.
  Waypoint? currentLocationWaypoint;

  /// The list for the routingBarItems
  List<Widget> routingBarItems = [];

  /// The list of waypoints for SearchRoutingView
  List<Waypoint?> routingItems = [];

  @override
  void didChangeDependencies() {
    geosearch = Provider.of<Geosearch>(context);
    routingService = Provider.of<Routing>(context);
    profile = Provider.of<Profile>(context);
    positioning = Provider.of<Positioning>(context);
    updateWaypoint();
    updateRoutingBarItems();

    super.didChangeDependencies();
  }

  /// update the routingBarItems
  updateRoutingBarItems() {
    if (routingService.selectedWaypoints != null) {
      routingBarItems = [];
      for (int i = 0; i < routingService.selectedWaypoints!.length; i++) {
        routingBarItems.add(_routingBarRow(
            i,
            routingService.selectedWaypoints!.length,
            routingService.selectedWaypoints![i]));
      }
    } else {
      if (widget.fromRoutingSearch) {
        if (profile.setLocationAsStart != null &&
            profile.setLocationAsStart! &&
            currentLocationWaypoint != null) {
          routingItems = [currentLocationWaypoint, null];
        } else {
          routingItems = [null, null];
        }
      }
    }
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

  _routingBarRow(int index, int max, Waypoint? waypoint) {
    IconData? leadingIcon;
    if (index == 0) leadingIcon = Icons.gps_fixed_outlined;
    if (index == max - 1) leadingIcon = Icons.location_on;

    IconData? trailingIcon;
    if (index < max - 1) trailingIcon = Icons.remove;
    if (index == max - 1) trailingIcon = Icons.add;

    return Row(
      key: Key('$index'),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              leadingIcon != null
                  ? Icon(leadingIcon)
                  : Container(
                      width: 24,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white)),
                      child: Center(
                        child:
                            Content(text: index.toString(), context: context),
                      ),
                    ),
              index < max - 1
                  ? Positioned(
                      left: 3,
                      top: index == 0 ? 23 : 20,
                      child: const Icon(
                        Icons.more_vert,
                        size: 18,
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: GestureDetector(
                onTap: () {
                  onSearch(context, routingService, profile,
                      currentLocationWaypoint, index, false);
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 20, right: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      bottomLeft: Radius.circular(25),
                    ),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Content(
                        text: waypoint != null
                            ? waypoint.address != null
                                ? waypoint.address!.toString()
                                : "Aktueller Standort"
                            : index > 0
                                ? "Ziel auswählen"
                                : "Start auswählen",
                        context: context,
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 5),
          child: IconButton(
            constraints: const BoxConstraints(maxHeight: 40),
            iconSize: 20,
            icon: Icon(trailingIcon),
            onPressed: () {
              if (index < max - 1) {
                onRemoveWaypoint(context, index, max);
              } else {
                onSearch(context, routingService, profile,
                    currentLocationWaypoint, null, false);
              }
            },
            splashRadius: 20,
          ),
        )
      ],
    );
  }

  /// A callback which is executed when the map was created.
  Future<void> onRemoveWaypoint(
      BuildContext context, int index, int max) async {
    if (index < max - 1 && routingService.selectedWaypoints != null) {
      if (routingService.selectedWaypoints == null ||
          routingService.selectedWaypoints!.isEmpty) return;

      final removedWaypoints = routingService.selectedWaypoints!.toList();
      removedWaypoints.removeAt(index);

      routingService.selectWaypoints(removedWaypoints);
      routingService.loadRoutes(context);
    }
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Material(
          elevation: 0,
          color: Colors.transparent,
          child: child,
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    final List<Widget> searchRoutingBarItems = [];
    if (widget.fromRoutingSearch) {
      for (int i = 0; i < routingItems.length; i++) {
        searchRoutingBarItems
            .add(_routingBarRow(i, routingItems.length, routingItems[i]));
      }
    }

    return Material(
      elevation: 5,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        width: frame.size.width,
        child: SafeArea(
          top: true,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Hero(
                tag: 'appBackButton',
                child: AppBackButton(
                    icon: Icons.chevron_left_rounded,
                    onPressed: () {
                      routingService.reset();
                      // only in SearchRoutingView
                      if (widget.fromRoutingSearch) {
                        Navigator.of(context).pop();
                      }
                    },
                    elevation: 5),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: frame.size.height * 0.25,
                  ),
                  child: ReorderableListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    proxyDecorator: _proxyDecorator,
                    // With a newer Version of Flutter onReorderStart can be used to hide symbols during drag
                    onReorder: (int oldIndex, int newIndex) {
                      if (routingService.selectedWaypoints != null) {
                        // Catch out of range. ReorderableList sets newIndex to list.length() + 1 if its way below
                        if (newIndex >=
                            routingService.selectedWaypoints!.length) {
                          newIndex =
                              routingService.selectedWaypoints!.length - 1;
                        }
                        if (oldIndex == newIndex) return;
                        // Tell the tutorial that the user has changed the order of the waypoints.
                        Provider.of<Tutorial>(context, listen: false)
                            .complete("priobike.tutorial.draw-waypoints");

                        if (routingService.selectedWaypoints == null ||
                            routingService.selectedWaypoints!.isEmpty) return;

                        final reorderedWaypoints =
                            routingService.selectedWaypoints!.toList();
                        final waypoint = reorderedWaypoints.removeAt(oldIndex);
                        reorderedWaypoints.insert(newIndex, waypoint);

                        routingService.selectWaypoints(reorderedWaypoints);
                        routingService.loadRoutes(context);
                      } else {
                        // on reorder when in SearchRoutingView
                        // Catch out of range. ReorderableList sets newIndex to list.length() + 1 if its way below
                        if (newIndex >= routingItems.length) {
                          newIndex = routingItems.length - 1;
                        }
                        if (oldIndex == newIndex) return;
                        setState(() {
                          final waypoint = routingItems.removeAt(oldIndex);
                          routingItems.insert(newIndex, waypoint);
                        });
                      }
                    },
                    children: widget.fromRoutingSearch
                        ? searchRoutingBarItems
                        : routingBarItems,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
