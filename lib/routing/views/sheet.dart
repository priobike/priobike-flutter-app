import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/details/discomforts.dart';
import 'package:priobike/routing/views/details/height.dart';
import 'package:priobike/routing/views/details/road.dart';
import 'package:priobike/routing/views/details/surface.dart';
import 'package:priobike/routing/views/details/waypoints.dart';
import 'package:priobike/routing/views/search.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/traffic/views/traffic_chart.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:priobike/tutorial/view.dart';

/// A bottom sheet to display route details.
class RouteDetailsBottomSheet extends StatefulWidget {
  /// A callback that is executed when the riding is started.
  final void Function() onSelectStartButton;

  /// A callback that is executed when a shortcut should be saved.
  final void Function() onSelectSaveButton;

  const RouteDetailsBottomSheet({required this.onSelectStartButton, required this.onSelectSaveButton, super.key});

  @override
  State<StatefulWidget> createState() => RouteDetailsBottomSheetState();
}

class RouteDetailsBottomSheetState extends State<RouteDetailsBottomSheet> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated status service, which is injected by the provider.
  late PredictionSGStatus status;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    routing = getIt<Routing>();
    routing.addListener(update);
    status = getIt<PredictionSGStatus>();
    status.addListener(update);
  }

  @override
  void dispose() {
    routing.removeListener(update);
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

    routing.selectWaypoints(reorderedWaypoints);
    routing.loadRoutes();
  }

  /// A callback that is executed when the search page is opened.
  Future<void> onSearch() async {
    final bool showOwnLocationInSearch = routing.selectedWaypoints != null ? true : false;
    final result = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => RouteSearch(showCurrentPositionAsWaypoint: showOwnLocationInSearch)));
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

    routing.selectWaypoints(newWaypoints);
    routing.loadRoutes();
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
    if (routing.isFetchingRoute) return Container();
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
        margin: const EdgeInsets.only(left: 8, top: 32),
        width: 16,
        height: (routing.selectedWaypoints?.length ?? 0) * 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey,
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
        ],
      )
    ]);
  }

  /// Render an info section on top of the bottom sheet.
  Widget renderTopInfoSection(BuildContext context) {
    if (routing.selectedRoute == null) return Container();

    var text = "Zum Ziel";
    if (routing.selectedProfile?.explanation != null) {
      text = routing.selectedProfile!.explanation;
    }
    final int okTrafficLights = status.ok;
    final int allTrafficLights = status.ok + status.bad + status.offline;

    String textTrafficLights;
    double percentageTrafficLights = 0;

    if (allTrafficLights > 0) {
      textTrafficLights =
          "$allTrafficLights Ampeln angebunden, $okTrafficLights davon haben Geschwindigkeitsempfehlungen";
      percentageTrafficLights = okTrafficLights / allTrafficLights;
    } else {
      textTrafficLights = "Es befinden sich keine Ampeln auf der Route";
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Column(children: [
          Small(text: text, context: context),
          const SizedBox(height: 2),
          BoldSmall(
              text:
                  "${routing.selectedRoute!.timeText} - ${routing.selectedRoute!.arrivalTimeText}, ${routing.selectedRoute!.lengthText}",
              context: context),
          const SizedBox(height: 2),
          Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
              child: Small(
                text: textTrafficLights,
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
          const SmallVSpace(),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return SizedBox(
      height: frame.size.height, // Needed for reorderable list.
      child: Stack(children: [
        DraggableScrollableSheet(
          initialChildSize: 140 / frame.size.height + (frame.padding.bottom / frame.size.height),
          maxChildSize: 1,
          minChildSize: 140 / frame.size.height + (frame.padding.bottom / frame.size.height),
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      height: routing.isFetchingRoute ? 48 : 0,
                      child: Icon(
                        Icons.directions_bike,
                        size: routing.isFetchingRoute ? 48 : 0,
                        color: Theme.of(context).colorScheme.onTertiary,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      // Hides the content while fetching the route, then slides it in.
                      height: routing.isFetchingRoute ? 0 : null,
                      child: Column(
                        children: [
                          renderTopInfoSection(context),
                          const SmallVSpace(),
                          renderBottomSheetWaypoints(context),
                          if (routing.selectedWaypoints == null || routing.selectedWaypoints!.isEmpty)
                            const TutorialView(
                              id: "priobike.tutorial.draw-waypoints",
                              text: "Durch langes Drücken auf die Karte kannst Du direkt einen Wegpunkt platzieren.",
                              padding: EdgeInsets.only(left: 18),
                            ),
                          const Padding(padding: EdgeInsets.only(top: 24), child: RoadClassChart()),
                          const Padding(padding: EdgeInsets.only(top: 8), child: TrafficChart()),
                          const Padding(padding: EdgeInsets.only(top: 8), child: RouteHeightChart()),
                          const Padding(padding: EdgeInsets.only(top: 8), child: SurfaceTypeChart()),
                          const Padding(padding: EdgeInsets.only(top: 8), child: DiscomfortsChart()),
                          // Big button size + padding.
                          SizedBox(
                            height: 40 + 8 + frame.padding.bottom,
                          ),
                        ],
                      ),
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
