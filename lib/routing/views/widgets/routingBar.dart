import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/bottomSheetState.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/search.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:provider/provider.dart';

/// A callback that is executed when the search page is opened.
Future<void> onSearch(BuildContext context, Routing routing, int? index, Function onPressed) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SearchView(index: index, onPressed: onPressed),
    ),
  );

  if (routing.selectedWaypoints != null &&
      routing.selectedWaypoints!.isNotEmpty) {
    await routing.loadRoutes(context);
  }
}

/// A view that displays alerts in the routingOLD context.
class RoutingBar extends StatefulWidget {
  final TextEditingController? locationSearchController;
  final bool fromRoutingSearch;
  final Function? checkNextItem;
  final Function onPressed;

  const RoutingBar(
      {Key? key,
      this.locationSearchController,
      required this.fromRoutingSearch,
      required this.onPressed,
      this.checkNextItem})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingBarState();
}

class RoutingBarState extends State<RoutingBar> {
  /// The geosearch service that is injected by the provider.
  late Geosearch geosearch;

  /// The associated routingOLD service, which is injected by the provider.
  late Routing routing;

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

  @override
  void didChangeDependencies() {
    geosearch = Provider.of<Geosearch>(context);
    routing = Provider.of<Routing>(context);
    profile = Provider.of<Profile>(context);
    positioning = Provider.of<Positioning>(context);
    bottomSheetState = Provider.of<BottomSheetState>(context);
    updateWaypoint();
    updateRoutingBarItems();

    super.didChangeDependencies();
  }

  /// update the routingBarItems
  updateRoutingBarItems() {
    if (routing.selectedWaypoints != null) {
      routingBarItems = [];
      for (int i = 0; i < routing.selectedWaypoints!.length; i++) {
        routingBarItems.add(_routingBarRow(i, routing.selectedWaypoints!.length,
            routing.selectedWaypoints![i], routing.nextItem));
      }
    } else {
      if (widget.fromRoutingSearch && routing.routingItems.isEmpty) {
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
    currentLocationWaypoint = Waypoint(positioning.lastPosition!.latitude,
        positioning.lastPosition!.longitude);
  }

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
                  if (widget.fromRoutingSearch) {
                    _onSearchRoutingBar(context, index, false);
                  } else {
                    onSearch(context, routing, index, widget.onPressed);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 20, right: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      bottomLeft: Radius.circular(25),
                    ),
                    border: Border.all(
                        color: nextItem == index
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey),
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
                if (index == 0 && max == 2) {
                  swapWaypoints(context);
                } else {
                  onRemoveWaypoint(context, index, max);
                }
              } else {
                if (widget.fromRoutingSearch) {
                  _onSearchRoutingBar(context, index, true);
                } else {
                  onSearch(context, routing, null, widget.onPressed);
                }
              }
            },
            splashRadius: 20,
          ),
        )
      ],
    );
  }

  /// A function which swaps the waypoints if exactly 2 are selected and the swap button is pressed.
  void swapWaypoints(BuildContext context) {
    if (routing.selectedWaypoints == null ||
        routing.selectedWaypoints!.length != 2) return;

    final waypointsSwapped = [
      routing.selectedWaypoints![1],
      routing.selectedWaypoints![0]
    ];

    routing.selectWaypoints(waypointsSwapped);
    routing.loadRoutes(context);
  }

  /// A function which removes the selected waypoint.
  void onRemoveWaypoint(BuildContext context, int index, int max) {
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
        if (routing.selectedWaypoints == null ||
            routing.selectedWaypoints!.isEmpty) return;

        final removedWaypoints = routing.selectedWaypoints!.toList();
        removedWaypoints.removeAt(index);

        routing.selectWaypoints(removedWaypoints);
        routing.loadRoutes(context);
      }
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

  /// A callback that is executed when the search page is opened in SearchRoutingView
  _onSearchRoutingBar(BuildContext context, int index, bool append) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchView(index: index, onPressed: widget.onPressed),
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

    final List<Widget> searchRoutingBarItems = [];
    if (widget.fromRoutingSearch) {
      for (int i = 0; i < routing.routingItems.length; i++) {
        searchRoutingBarItems.add(_routingBarRow(i, routing.routingItems.length,
            routing.routingItems[i], routing.nextItem));
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
                      // Reset everything.
                      routing.reset();
                      bottomSheetState.listController = null;
                      bottomSheetState.resetInitialHeight();
                      bottomSheetState.draggableScrollableController.reset();

                      // Only in SearchRoutingView.
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
                      if (routing.selectedWaypoints != null) {
                        // Catch out of range. ReorderableList sets newIndex to list.length() + 1 if its way below
                        if (newIndex >= routing.selectedWaypoints!.length) {
                          newIndex = routing.selectedWaypoints!.length - 1;
                        }
                        if (oldIndex == newIndex) return;
                        // Tell the tutorial that the user has changed the order of the waypoints.
                        Provider.of<Tutorial>(context, listen: false)
                            .complete("priobike.tutorial.draw-waypoints");

                        if (routing.selectedWaypoints == null ||
                            routing.selectedWaypoints!.isEmpty) return;

                        final reorderedWaypoints =
                            routing.selectedWaypoints!.toList();
                        final waypoint = reorderedWaypoints.removeAt(oldIndex);
                        reorderedWaypoints.insert(newIndex, waypoint);

                        routing.selectWaypoints(reorderedWaypoints);
                        routing.loadRoutes(context);
                      } else {
                        // on reorder when in SearchRoutingView
                        // Catch out of range. ReorderableList sets newIndex to list.length() + 1 if its way below
                        if (newIndex >= routing.routingItems.length) {
                          newIndex = routing.routingItems.length - 1;
                        }
                        if (oldIndex == newIndex) return;
                        setState(() {
                          final waypoint =
                              routing.routingItems.removeAt(oldIndex);
                          routing.routingItems.insert(newIndex, waypoint);
                        });
                        widget.checkNextItem!();
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
