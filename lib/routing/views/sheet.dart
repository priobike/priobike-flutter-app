import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/details/height.dart';
import 'package:priobike/routing/views/details/road.dart';
import 'package:priobike/routing/views/details/surface.dart';
import 'package:priobike/routing/views/details/waypoints.dart';
import 'package:priobike/routing/views/search.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/traffic/services/traffic_service.dart';
import 'package:priobike/tutorial/service.dart';

/// A bottom sheet to display route details.
class RouteDetailsBottomSheet extends StatefulWidget {
  /// A callback that is executed when the riding is started.
  final void Function() onSelectStartButton;

  /// A callback that is executed when a shortcut should be saved.
  final void Function() onSelectSaveButton;

  const RouteDetailsBottomSheet({required this.onSelectStartButton, required this.onSelectSaveButton, Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => RouteDetailsBottomSheetState();
}

class RouteDetailsBottomSheetState extends State<RouteDetailsBottomSheet> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated position service, which is injected by the provider.
  late Positioning positioning;

  /// The associated status service, which is injected by the provider.
  late PredictionSGStatus status;

  late TrafficService trafficService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    routing = getIt<Routing>();
    routing.addListener(update);
    positioning = getIt<Positioning>();
    positioning.addListener(update);
    status = getIt<PredictionSGStatus>();
    status.addListener(update);
    trafficService = getIt<TrafficService>();
    trafficService.addListener(update);
  }

  @override
  void dispose() {
    routing.removeListener(update);
    positioning.removeListener(update);
    status.removeListener(update);
    trafficService.removeListener(update);
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
      if (positioning.lastPosition != null) {
        waypoints.add(Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude));
      }
    }
    final newWaypoints = [...waypoints, waypoint];

    routing.selectWaypoints(newWaypoints);
    routing.loadRoutes();
  }

  /// A callback that is executed when the user removes a waypoint.
  Future<void> onRemoveWaypoint(int index) async {
    if (routing.selectedWaypoints == null || routing.selectedWaypoints!.isEmpty) return;

    final removedWaypoints = routing.selectedWaypoints!.toList();
    removedWaypoints.removeAt(index);

    routing.selectWaypoints(removedWaypoints);
    routing.loadRoutes();
  }

  /// Element for Bar Chart for Traffic Prediction. The Bar for the current time is highlighted.
  Widget renderTrafficBar(double height, int time, bool highlightHourNow) {
    final availableWidth = (MediaQuery.of(context).size.width - 24);
    return Column(
      children: [
        Container(
          // max. 7 bars + 5 padding on each side
          width: availableWidth / 7 - 10,
          height: height,
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: !highlightHourNow
                  ? [
                      const Color.fromARGB(255, 166, 168, 168),
                      const Color.fromARGB(255, 214, 215, 216),
                    ]
                  : [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
            ),
            shape: BoxShape.rectangle,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5),
            ),
          ),
        ),
        Small(
          text: "$time:00",
          context: context,
        )
      ],
    );
  }

  /// Render the Traffic Prediction Bar Chart.
  Widget renderTrafficPrediction(BuildContext context) {
    trafficService.fetch();
    final availableHeight = (MediaQuery.of(context).size.height);
    return (trafficService.hasLoaded == true)
        ? Padding(
            padding: const EdgeInsets.only(top: 16, left: 4, right: 4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Content(
                      text: "Verkehrslage",
                      context: context,
                    ),
                    Content(
                      text: trafficService.trafficStatus!,
                      context: context,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final key in trafficService.trafficData!.keys)
                      if (trafficService.trafficData![key] != null)
                        renderTrafficBar(
                            (trafficService.trafficData![key]! - trafficService.lowestValue! * 0.99) *
                                availableHeight *
                                5,
                            int.parse(key),
                            (int.parse(key) == DateTime.now().hour))
                  ],
                ),
              ],
            ),
          )
        : Container();
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
        onDelete: () => onRemoveWaypoint(i),
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
          color: Theme.of(context).colorScheme.primary,
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
    final distInfo = "${((routing.selectedRoute!.path.distance) / 1000).toStringAsFixed(1)} km";
    final seconds = routing.selectedRoute!.path.time / 1000;
    // Get the full hours needed to cover the route.
    final hours = seconds ~/ 3600;
    // Get the remaining minutes.
    final minutes = (seconds - hours * 3600) ~/ 60;
    // Calculate the time when the user will reach the destination.
    final arrivalTime = DateTime.now().add(Duration(seconds: seconds.toInt()));
    var text = "Zum Ziel";
    if (routing.selectedProfile?.explanation != null) {
      text = routing.selectedProfile!.explanation;
    }
    text += " - ${(status.okPercentage * 100).toInt()}% Grüne Welle möglich";
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: Column(
        children: [
          BoldSmall(
            text: text,
            color: Theme.of(context).colorScheme.brightness == Brightness.dark
                ? const Color.fromARGB(255, 0, 255, 106)
                : const Color.fromARGB(255, 0, 220, 92),
            context: context,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          BoldSmall(
              text:
                  "${hours == 0 ? '' : '$hours Std. '}$minutes Min. - Ankunft ca. ${arrivalTime.hour}:${arrivalTime.minute.toString().padLeft(2, "0")} Uhr, $distInfo",
              context: context),
        ],
      ),
    );
  }

  /// Render the start ride button.
  Widget renderStartRideButton(BuildContext context) {
    if (routing.selectedRoute == null) return Container();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: BigButton(
        iconColor: Colors.white,
        label: "Losfahren",
        onPressed: widget.onSelectStartButton,
        boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
      ),
    );
  }

  /// Render the save route button.
  Widget renderSaveRouteButton(BuildContext context) {
    if (routing.selectedRoute == null) return Container();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      child: BigButton(
        iconColor: Colors.white,
        label: "Strecke speichern",
        onPressed: widget.onSelectSaveButton,
        boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return SizedBox(
      height: frame.size.height, // Needed for reorderable list.
      child: DraggableScrollableSheet(
        initialChildSize: 116 / frame.size.height + (frame.padding.bottom / frame.size.height),
        maxChildSize: 1,
        minChildSize: 116 / frame.size.height + (frame.padding.bottom / frame.size.height),
        builder: (BuildContext context, ScrollController controller) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 0, blurRadius: 16)],
            ),
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                children: [
                  renderDragIndicator(context),
                  renderTopInfoSection(context),
                  renderStartRideButton(context),
                  renderBottomSheetWaypoints(context),
                  const Padding(padding: EdgeInsets.only(top: 8, left: 4, right: 4), child: RoadClassChart()),
                  renderTrafficPrediction(context),
                  const RouteHeightChart(),
                  const Padding(padding: EdgeInsets.only(top: 4, left: 4, right: 4), child: SurfaceTypeChart()),
                  renderSaveRouteButton(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
