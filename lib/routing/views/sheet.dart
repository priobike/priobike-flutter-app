import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/map_functions.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/details/height.dart';
import 'package:priobike/routing/views/details/poi.dart';
import 'package:priobike/routing/views/details/road.dart';
import 'package:priobike/routing/views/details/surface.dart';
import 'package:priobike/routing/views/details/waypoints.dart';
import 'package:priobike/routing/views/search.dart';
import 'package:priobike/routing/views/widgets/loading_icon.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/traffic/views/traffic_chart.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:priobike/tutorial/view.dart';

/// A bottom sheet to display route details.
class RouteDetailsBottomSheet extends StatefulWidget {
  /// The associated map functions service, which is injected by the provider.
  final MapFunctions mapFunctions;

  /// A callback that is executed when the riding is started.
  final void Function() onSelectStartButton;

  /// A callback that is executed when a shortcut should be saved.
  final void Function() onSelectSaveButton;

  /// Whether the parent view has everything initially loaded.
  final bool hasInitiallyLoaded;

  const RouteDetailsBottomSheet({
    super.key,
    required this.onSelectStartButton,
    required this.onSelectSaveButton,
    required this.hasInitiallyLoaded,
    required this.mapFunctions,
  });

  @override
  State<StatefulWidget> createState() => RouteDetailsBottomSheetState();
}

class RouteDetailsBottomSheetState extends State<RouteDetailsBottomSheet> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated status service, which is injected by the provider.
  late PredictionSGStatus status;

  /// The scroll controller for the bottom sheet.
  late DraggableScrollableController controller;

  /// The initial child size of the bottom sheet.
  late double initialChildSize;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    if (widget.mapFunctions.tappedWaypointIdx != null || widget.mapFunctions.selectPointOnMap) {
      // reset scroll extend when waypoint tapped.
      controller.animateTo(initialChildSize, duration: const Duration(milliseconds: 500), curve: Curves.easeInCubic);
    }
    setState(() {});
  }

  /// A timer that updates the arrival time every minute.
  Timer? arrivalTimeUpdateTimer;

  @override
  void initState() {
    super.initState();

    arrivalTimeUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) => update());

    routing = getIt<Routing>();
    routing.addListener(update);
    status = getIt<PredictionSGStatus>();
    status.addListener(update);
    widget.mapFunctions.addListener(update);
    controller = DraggableScrollableController();
  }

  @override
  void dispose() {
    arrivalTimeUpdateTimer?.cancel();
    arrivalTimeUpdateTimer = null;

    routing.removeListener(update);
    widget.mapFunctions.removeListener(update);
    status.removeListener(update);
    super.dispose();
  }

  /// A callback that is executed when the order of the waypoints change.
  Future<void> onChangeWaypointOrder(int oldIndex, int newIndex) async {
    // Tell the tutorial that the user has changed the order of the waypoints.
    getIt<Tutorial>().complete("priobike.tutorial.draw-waypoints");

    if (oldIndex == newIndex) return;
    if (routing.selectedWaypoints == null || routing.selectedWaypoints!.isEmpty) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final reorderedWaypoints = routing.selectedWaypoints!.toList();
    final waypoint = reorderedWaypoints.removeAt(oldIndex);
    reorderedWaypoints.insert(newIndex, waypoint);

    await routing.selectWaypoints(reorderedWaypoints);
    // load asynchronously and check in build method if route is ready
    unawaited(routing.loadRoutes());
  }

  /// A callback that is executed when the search page is opened.
  Future<void> onSearch() async {
    // Close the bottom sheet to the initial size.
    controller.animateTo(initialChildSize, duration: const Duration(milliseconds: 100), curve: Curves.easeInOutCubic);

    final bool showOwnLocationInSearch = routing.selectedWaypoints != null ? true : false;
    final result = await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RouteSearch(
              showCurrentPositionAsWaypoint: showOwnLocationInSearch,
              mapFunctions: widget.mapFunctions,
            )));
    if (result == null) return;

    final waypoint = result as Waypoint;
    final waypoints = routing.selectedWaypoints ?? [];

    // Add the own location as a start point to the route, if the waypoint selected in the search is the
    // first waypoint of the route. Thus making it the destination of the route.
    if (waypoints.isEmpty) {
      final positioning = getIt<Positioning>();
      if (positioning.lastPosition != null) {
        waypoints.add(Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude));
      }
    }
    final newWaypoints = [...waypoints, waypoint];

    await routing.selectWaypoints(newWaypoints);
    // load asynchronously and check in build method if route is ready
    unawaited(routing.loadRoutes());
  }

  /// The callback that is executed when select on map is tapped.
  void onSelectOnMap() {
    widget.mapFunctions.setSelectPointOnMap();
  }

  Widget renderDragIndicator(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.center,
      width: 32,
      height: 6,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
    );
  }

  Widget renderBottomSheetWaypoints(BuildContext context) {
    var widgets = <Widget>[];
    for (int i = 0; i < (routing.selectedWaypoints?.length ?? 0); i++) {
      final waypoint = routing.selectedWaypoints![i];
      widgets.add(RouteWaypointItem(
        onDelete: () => routing.removeWaypointAt(i),
        key: Key("$i"),
        count: routing.selectedWaypoints?.length ?? 0,
        idx: i,
        waypoint: waypoint,
      ));
    }
    return Stack(children: [
      Container(
        margin: const EdgeInsets.only(left: 7, top: 32),
        width: 18,
        height: (routing.selectedWaypoints?.length ?? 0) * 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: CI.routeBackground,
        ),
      ),
      Container(
        margin: const EdgeInsets.only(left: 9, top: 32),
        width: 14,
        height: (routing.selectedWaypoints?.length ?? 0) * 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: CI.route,
        ),
      ),
      Column(
        children: [
          LayoutBuilder(
            builder: ((context, constraints) {
              return ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                proxyDecorator: (proxyWidget, idx, anim) => proxyWidget,
                onReorder: onChangeWaypointOrder,
                children: widgets,
              );
            }),
          ),
          SearchWaypointItem(onSelect: onSearch),
          const SmallVSpace(),
          Row(children: [
            Expanded(
              child: BigButtonSecondary(
                label: "Auf Karte auswählen",
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                onPressed: onSelectOnMap,
              ),
            ),
          ]),
        ],
      )
    ]);
  }

  /// Render an info section on top of the bottom sheet.
  Widget renderTopInfoSection(BuildContext context) {
    if (routing.selectedRoute == null) return Container();

    final int okTrafficLights = routing.selectedRoute!.ok;
    final int allTrafficLights =
        routing.selectedRoute!.ok + routing.selectedRoute!.bad + routing.selectedRoute!.offline;

    double percentageTrafficLights = allTrafficLights > 0 ? okTrafficLights / allTrafficLights : 0;

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Column(children: [
          const SizedBox(height: 2),
          BoldSmall(
              text:
                  "${routing.selectedRoute!.timeText} - ${routing.selectedRoute!.arrivalTimeText}, ${routing.selectedRoute!.lengthText}",
              context: context),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(
              width: 18,
            ),
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
              padding: EdgeInsets.only(top: Platform.isAndroid ? 4 : 0),
              child: allTrafficLights > 0
                  ? Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(
                        style: const TextStyle(
                          height: 1.1,
                          fontFamily: 'HamburgSans',
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: okTrafficLights.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: okTrafficLights > 0 ? CI.radkulturGreen : null,
                            ),
                          ),
                          TextSpan(
                            text: " Ampel${allTrafficLights == 1 ? "" : "n"} mit Prognose",
                          ),
                        ],
                      ),
                    )
                  : Small(
                      text: "Es befinden sich keine Ampeln auf der Route",
                      context: context,
                      textAlign: TextAlign.center,
                      height: 1.1,
                    ),
            ),
            const SmallHSpace(),
            SizedBox(
              width: 18,
              height: 18,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percentageTrafficLights,
                    strokeWidth: 4,
                    backgroundColor: allTrafficLights > 0
                        ? CI.radkulturGreen.withOpacity(0.2)
                        : Theme.of(context).colorScheme.onTertiary,
                    valueColor: const AlwaysStoppedAnimation<Color>(CI.radkulturGreen),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: percentageTrafficLights > 0
                        ? CI.radkulturGreen.withOpacity(percentageTrafficLights)
                        : Theme.of(context).colorScheme.onTertiary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ]),
        ]),
      ]),
    );
  }

  /// Helper function to determine if the bottom sheet is ready to be displayed.
  bool _checkIfBottomSheetIsReady() {
    if (!widget.hasInitiallyLoaded) return false;

    // After loading Route
    if (!routing.isFetchingRoute && !status.isLoading && routing.selectedRoute != null) {
      return true;
    }

    // Free Routing or Shortcut Location
    if (routing.selectedWaypoints == null) return true;
    if (routing.selectedWaypoints!.length <= 1) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    initialChildSize = 118 / frame.size.height + (frame.padding.bottom / frame.size.height);

    final bottomSheetIsReady = _checkIfBottomSheetIsReady();

    return SizedBox(
      height: frame.size.height, // Needed for reorderable list.
      width: frame.size.width,
      child: Stack(children: [
        DraggableScrollableSheet(
          initialChildSize: initialChildSize,
          maxChildSize: 1,
          minChildSize: initialChildSize,
          controller: controller,
          builder: (BuildContext context, ScrollController controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 0, blurRadius: 16)],
              ),
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  children: [
                    renderDragIndicator(context),
                    if (!bottomSheetIsReady)
                      const SizedBox(
                        height: 32,
                        child: LoadingIcon(),
                      ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOutCubic,
                      opacity: bottomSheetIsReady ? 1 : 0,
                      child: bottomSheetIsReady
                          // This additional check is needed to prevent a flickering behavior when we add a new waypoint.
                          // (Stuff like the top info section would change during the animation and thus would cause a flickering effect.)
                          // A major refactor of the bottom sheet is needed to fix this properly.
                          ? Column(
                              children: [
                                renderTopInfoSection(context),
                                renderBottomSheetWaypoints(context),
                                if (routing.selectedWaypoints == null || routing.selectedWaypoints!.isEmpty)
                                  const TutorialView(
                                    id: "priobike.tutorial.draw-waypoints",
                                    text:
                                        "Durch langes Drücken auf die Karte kannst Du direkt einen Wegpunkt platzieren.",
                                    padding: EdgeInsets.only(left: 18),
                                  ),
                                const Padding(padding: EdgeInsets.only(top: 24), child: RoadClassChart()),
                                const Padding(padding: EdgeInsets.only(top: 8), child: TrafficChart()),
                                const Padding(padding: EdgeInsets.only(top: 8), child: RouteHeightChart()),
                                const Padding(padding: EdgeInsets.only(top: 8), child: SurfaceTypeChart()),
                                const Padding(padding: EdgeInsets.only(top: 8), child: PoisChart()),
                                // Big button size + padding.
                                SizedBox(
                                  height: 40 + 8 + frame.padding.bottom,
                                ),
                              ],
                            )
                          : Container(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0),
                  Theme.of(context).colorScheme.surfaceVariant,
                ],
                stops: const [0.0, 0.5],
              ),
            ),
            width: frame.size.width,
            height: frame.padding.bottom + 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SmallHSpace(),
                Expanded(
                  child: BigButtonSecondary(
                    label: "Speichern",
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    onPressed:
                        routing.isFetchingRoute || routing.selectedRoute == null ? null : widget.onSelectSaveButton,
                    addPadding: false,
                  ),
                ),
                const SmallHSpace(),
                Expanded(
                  child: BigButtonPrimary(
                    label: "Losfahren",
                    onPressed:
                        routing.isFetchingRoute || routing.selectedRoute == null ? null : widget.onSelectStartButton,
                    addPadding: false,
                  ),
                ),
                const SmallHSpace(),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
