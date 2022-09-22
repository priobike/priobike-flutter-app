import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routingNew/models/waypoint.dart';
import 'package:priobike/routingNew/services/geosearch.dart';
import 'package:priobike/routingNew/services/routing.dart';
import 'package:priobike/routingNew/views/search.dart';
import 'package:provider/provider.dart';

/// A view that displays alerts in the routing context.
class RoutingBar extends StatefulWidget {
  final TextEditingController? locationSearchController;

  const RoutingBar({Key? key, this.locationSearchController}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingBarState();
}

class RoutingBarState extends State<RoutingBar> {
  /// The geosearch service that is injected by the provider.
  late Geosearch geosearch;

  /// The associated routing service, which is injected by the provider.
  late Routing routingService;

  _routingBarRow(int index, int max, Waypoint waypoint) {
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SearchView(),
                    ),
                  );
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
                  child: Center(
                    child: Content(
                        text: waypoint.address.toString(),
                        context: context,
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: IconButton(
            constraints: const BoxConstraints(maxHeight: 40),
            iconSize: 20,
            icon: Icon(trailingIcon),
            onPressed: () => onRemoveWaypoint(context, index, max),
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

  @override
  void didChangeDependencies() {
    geosearch = Provider.of<Geosearch>(context);
    routingService = Provider.of<Routing>(context);
    super.didChangeDependencies();
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
    List<Widget> routingBarItems = [];
    if (routingService.selectedWaypoints != null) {
      for (int i = 0; i < routingService.selectedWaypoints!.length; i++) {
        routingBarItems.add(_routingBarRow(
            i,
            routingService.selectedWaypoints!.length,
            routingService.selectedWaypoints![i]));
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
                        Waypoint oldPos =
                            routingService.selectedWaypoints![oldIndex];
                        final newWaypointsList =
                            routingService.selectedWaypoints!.toList();

                        newWaypointsList[oldIndex] = newWaypointsList[newIndex];
                        newWaypointsList[newIndex] = oldPos;

                        routingService.selectWaypoints(newWaypointsList);
                        routingService.loadRoutes(context);
                      }
                    },
                    children: routingBarItems,
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
