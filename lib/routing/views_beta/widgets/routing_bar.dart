import 'dart:async';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/bottom_sheet_state.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views_beta/search.dart';
import 'package:priobike/routing/views_beta/widgets/calculate_routing_bar_height.dart';
import 'package:priobike/tutorial/service.dart';

/// A view that displays the routing bar.
class RoutingBar extends StatefulWidget {
  final TextEditingController? locationSearchController;
  final bool fromRoutingSearch;
  final Function? checkNextItem;
  final Function onPressed;
  final Function? onSearch;
  final StreamController<DraggableScrollableNotification> sheetMovement;

  const RoutingBar({
    Key? key,
    this.locationSearchController,
    required this.fromRoutingSearch,
    required this.onPressed,
    this.checkNextItem,
    this.onSearch,
    required this.sheetMovement,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingBarState();
}

class RoutingBarState extends State<RoutingBar> {
  /// The geosearch service that is injected by the provider.
  late Geosearch geosearch;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated discomforts service, which is injected by the provider.
  late Discomforts discomforts;

  /// The associated profile service, which is injected by the provider.
  late Profile profile;

  /// The associated position service, which is injected by the provider.
  late Positioning positioning;

  /// The associated bottomSheetState service, which is injected by the provider.
  late BottomSheetState bottomSheetState;

  /// The currently fetched address.
  Waypoint? currentLocationWaypoint;

  /// The list for the routingBarItems
  List<Widget> routingBarItems = [];

  /// Variable to not duplicate initial code which we can't execute in initState since the service is null.
  bool initDone = false;

  bool showItemRowIcons = true;

  /// Called when a listener callback of a ChangeNotifier is fired.
  late VoidCallback update;

  @override
  void initState() {
    super.initState();
    update = () {
      updateWaypoint();
      updateRoutingBarItems();
      setState(() {});
    };

    geosearch = getIt<Geosearch>();
    geosearch.addListener(update);
    routing = getIt<Routing>();
    routing.addListener(update);
    discomforts = getIt<Discomforts>();
    discomforts.addListener(update);
    profile = getIt<Profile>();
    profile.addListener(update);
    positioning = getIt<Positioning>();
    positioning.addListener(update);
    bottomSheetState = getIt<BottomSheetState>();
    bottomSheetState.addListener(update);

    updateWaypoint();
    updateRoutingBarItems();
  }

  @override
  void dispose() {
    geosearch.removeListener(update);
    routing.removeListener(update);
    discomforts.removeListener(update);
    profile.removeListener(update);
    positioning.removeListener(update);
    bottomSheetState.removeListener(update);
    super.dispose();
  }

  /// update the routingBarItems when selected route switched and initially sets routing Items for RouteSearchView.
  updateRoutingBarItems() {
    // Update items after selected route switch.
    if (routing.selectedWaypoints != null) {
      routingBarItems = [];
      for (int i = 0; i < routing.selectedWaypoints!.length; i++) {
        routingBarItems
            .add(_routingBarRow(i, routing.selectedWaypoints!.length, routing.selectedWaypoints![i], routing.nextItem));
      }
    } else {
      // Init routing items for RouteSearchView.
      if (widget.fromRoutingSearch && !initDone) {
        setState(() {
          initDone = true;
        });
        if (profile.setLocationAsStart && currentLocationWaypoint != null) {
          routing.routingItems = [currentLocationWaypoint, null];
          routing.nextItem = 1;
        } else {
          routing.routingItems = [null, null];
          routing.nextItem = 0;
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
    currentLocationWaypoint = Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude);
  }

  /// The widget that displays a routing bar row.
  _routingBarRow(int index, int max, Waypoint? waypoint, int nextItem) {
    IconData? leadingIcon;
    if (index == 0) leadingIcon = Icons.gps_fixed_outlined;
    if (index == max - 1) leadingIcon = Icons.location_on;

    IconData? trailingIcon;
    if (index < max - 1) trailingIcon = Icons.remove;
    if (max == 2 && index == 0) trailingIcon = Icons.swap_vert;
    if (index == max - 1) trailingIcon = Icons.add;

    return Row(
      key: Key('$index'),
      children: [
        showItemRowIcons
            ? Padding(
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
                              border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                            ),
                            child: Center(
                              child: Padding(
                                // Since new Font there has to be top padding.
                                padding: const EdgeInsets.only(top: 1),
                                child: Content(text: index.toString(), context: context),
                              ),
                            ),
                          ),
                    index < max - 1
                        ? Positioned(
                            left: 3,
                            top: index == 0 ? 23 : 21,
                            child: const Icon(
                              Icons.more_vert,
                              size: 18,
                            ),
                          )
                        : Container(),
                  ],
                ),
              )
            : Container(
                width: 34,
              ),
        Expanded(
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: GestureDetector(
                onTap: () {
                  if (widget.fromRoutingSearch) {
                    _onSearchRoutingBar(context, index, false);
                  } else {
                    widget.onSearch!(routing, index, widget.onPressed, widget.fromRoutingSearch);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 20, right: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      bottomLeft: Radius.circular(25),
                    ),
                    border: Border.all(color: nextItem == index ? Theme.of(context).colorScheme.primary : Colors.grey),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      // Since new Font there has to be top padding. FIXME
                      padding: const EdgeInsets.only(top: 3),
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
        ),
        SizedBox(
          height: 40,
          width: 50,
          child: showItemRowIcons
              ? Padding(
                  padding: const EdgeInsets.only(left: 5, right: 5),
                  child: IconButton(
                    constraints: const BoxConstraints(maxHeight: 34),
                    iconSize: 20,
                    icon: Icon(trailingIcon),
                    onPressed: () async {
                      if (index < max - 1) {
                        if (index == 0 && max == 2) {
                          swapWaypoints();
                        } else {
                          onRemoveWaypoint(index, max);
                        }
                      } else {
                        if (widget.fromRoutingSearch) {
                          // Adding empty waypoint in routeSearchView.
                          routing.routingItems.add(null);
                          routing.notifyListeners();
                        } else {
                          widget.onSearch!(routing, null, widget.onPressed, widget.fromRoutingSearch);
                        }
                      }
                    },
                    splashRadius: 20,
                  ),
                )
              : Container(),
        ),
      ],
    );
  }

  /// A function which swaps the waypoints if exactly 2 are selected and the swap button is pressed.
  void swapWaypoints() {
    if (routing.selectedWaypoints == null || routing.selectedWaypoints!.length != 2) return;

    final waypointsSwapped = [routing.selectedWaypoints![1], routing.selectedWaypoints![0]];

    routing.selectWaypoints(waypointsSwapped);
    routing.loadRoutes();
  }

  /// A function which removes the selected waypoint.
  void onRemoveWaypoint(int index, int max) {
    if (widget.fromRoutingSearch) {
      if (index != 0 && routing.routingItems.length > 2) {
        setState(() {
          routing.routingItems.removeAt(index);
        });
        widget.checkNextItem!();
      } else {
        setState(() {
          routing.routingItems[index] = null;
        });
        widget.checkNextItem!();
      }
    } else {
      if (index < max - 1 && routing.selectedWaypoints != null) {
        if (routing.selectedWaypoints == null || routing.selectedWaypoints!.isEmpty) return;

        final removedWaypoints = routing.selectedWaypoints!.toList();
        removedWaypoints.removeAt(index);

        routing.selectWaypoints(removedWaypoints);
        routing.loadRoutes();
      }
    }
  }

  /// The proxy decorator used to style the reorderable list.
  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    // Updated Item needed to hide side icons.
    Widget updatedItemRow = widget.fromRoutingSearch
        ? _routingBarRow(index, routing.routingItems.length, routing.routingItems[index], routing.nextItem)
        : _routingBarRow(index, routing.selectedWaypoints!.length, routing.selectedWaypoints![index], routing.nextItem);

    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Material(
          elevation: 0,
          color: Colors.transparent,
          child: updatedItemRow,
        );
      },
      child: updatedItemRow,
    );
  }

  /// A callback that is executed when the search page is opened in SearchRoutingView
  _onSearchRoutingBar(BuildContext context, int index, bool append) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SearchView(index: index, onPressed: widget.onPressed, fromRouteSearch: widget.fromRoutingSearch),
      ),
    );

    if (result == null) return;

    setState(() {
      if (append) {
        routing.routingItems.add(result);
      } else {
        routing.routingItems[index] = result as Waypoint;
      }
      widget.checkNextItem!();
    });
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    List<Widget> searchRoutingBarItems = [];
    if (widget.fromRoutingSearch) {
      for (int i = 0; i < routing.routingItems.length; i++) {
        searchRoutingBarItems
            .add(_routingBarRow(i, routing.routingItems.length, routing.routingItems[i], routing.nextItem));
      }
    } else {
      if (routing.selectedWaypoints != null) {
        routingBarItems = [];
        for (int i = 0; i < routing.selectedWaypoints!.length; i++) {
          routingBarItems.add(
              _routingBarRow(i, routing.selectedWaypoints!.length, routing.selectedWaypoints![i], routing.nextItem));
        }
      }
    }

    return Material(
      elevation: 5,
      child: Container(
        color: Theme.of(context).colorScheme.background,
        width: frame.size.width,
        child: SafeArea(
          top: true,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedContainer(
              height: calculateRoutingBarHeight(
                  frame,
                  widget.fromRoutingSearch ? routing.routingItems.length : routing.selectedWaypoints!.length,
                  false,
                  routing.minimized),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInCubic,
              child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Hero(
                    tag: 'appBackButton',
                    child: AppBackButton(
                        icon: Icons.chevron_left_rounded,
                        onPressed: () {
                          // Reset everything.
                          routing.reset();
                          discomforts.reset();

                          // Only in SearchRoutingView.
                          if (widget.fromRoutingSearch) {
                            Navigator.of(context).pop();
                          } else {
                            bottomSheetState.reset();
                          }
                          widget.sheetMovement.add(DraggableScrollableNotification(
                              minExtent: 0, context: context, extent: 0.0, initialExtent: 0.0, maxExtent: 0.0));
                        },
                        elevation: 5),
                  ),
                ),
                !widget.fromRoutingSearch && routing.selectedWaypoints != null && routing.selectedWaypoints!.length >= 4
                    ? IconButton(
                        icon: routing.minimized
                            ? const Icon(Icons.keyboard_arrow_down)
                            : const Icon(Icons.keyboard_arrow_up),
                        onPressed: () {
                          routing.switchMinimized();
                        },
                      )
                    : Container(),
                // Expanded(child: Container(color: Colors.red,))
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AnimatedContainer(
                height: calculateRoutingBarHeight(
                    frame,
                    widget.fromRoutingSearch ? routing.routingItems.length : routing.selectedWaypoints!.length,
                    false,
                    routing.minimized),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInCubic,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ReorderableListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    proxyDecorator: _proxyDecorator,
                    // With a newer Version of Flutter onReorderStart can be used to hide symbols during drag
                    onReorderStart: (int index) {
                      setState(() {
                        showItemRowIcons = false;
                      });
                    },
                    onReorder: (int oldIndex, int newIndex) {
                      if (routing.selectedWaypoints != null) {
                        // Catch out of range. ReorderableList sets newIndex to list.length() + 1 if its way below
                        if (newIndex >= routing.selectedWaypoints!.length) {
                          newIndex = routing.selectedWaypoints!.length - 1;
                        }
                        if (oldIndex == newIndex) return;
                        // Tell the tutorial that the user has changed the order of the waypoints.
                        getIt<Tutorial>().complete("priobike.tutorial.draw-waypoints");

                        if (routing.selectedWaypoints == null || routing.selectedWaypoints!.isEmpty) return;

                        final reorderedWaypoints = routing.selectedWaypoints!.toList();
                        final waypoint = reorderedWaypoints.removeAt(oldIndex);
                        reorderedWaypoints.insert(newIndex, waypoint);

                        routing.selectWaypoints(reorderedWaypoints);
                        routing.loadRoutes();
                      } else {
                        // on reorder when in SearchRoutingView
                        // Catch out of range. ReorderableList sets newIndex to list.length() + 1 if its way below
                        if (newIndex >= routing.routingItems.length) {
                          newIndex = routing.routingItems.length - 1;
                        }
                        if (oldIndex == newIndex) return;
                        setState(() {
                          final waypoint = routing.routingItems.removeAt(oldIndex);
                          routing.routingItems.insert(newIndex, waypoint);
                        });
                        widget.checkNextItem!();
                      }
                      setState(() {
                        showItemRowIcons = true;
                      });
                    },
                    children: widget.fromRoutingSearch ? searchRoutingBarItems : routingBarItems,
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
