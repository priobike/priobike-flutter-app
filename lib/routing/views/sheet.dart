import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/images.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/charts/height.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/search.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:priobike/tutorial/view.dart';
import 'package:provider/provider.dart';

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

class SearchWaypointItem extends StatelessWidget {
  /// A callback that is executed when the waypoint is selected.
  final void Function()? onSelect;

  const SearchWaypointItem({this.onSelect, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          const WaypointIcon(width: 32, height: 32),
          const SmallHSpace(),
          SizedBox(
            height: 42,
            width: frame.size.width - 114,
            child: Tile(
              fill: Theme.of(context).colorScheme.surface,
              onPressed: onSelect,
              padding: const EdgeInsets.all(10),
              content: Row(
                children: [
                  const SmallHSpace(),
                  Flexible(
                    child: BoldContent(
                      color: Colors.grey,
                      text: "Adresse suchen",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      context: context,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SmallHSpace(),
          SizedBox(
            width: 42,
            height: 42,
            child: RawMaterialButton(
              elevation: 0,
              fillColor: Theme.of(context).colorScheme.surface,
              splashColor: Colors.black,
              onPressed: onSelect,
              shape: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.search,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class RouteWaypointItem extends StatelessWidget {
  /// A callback that is executed when the item is deleted.
  final void Function()? onDelete;

  /// The associated waypoint.
  final Waypoint waypoint;

  /// The index of the waypoint in the route.
  final int idx;

  /// The total number of waypoints.
  final int count;

  /// If the waypoint is the first waypoint.
  bool get isFirst => idx == 0;

  /// If the waypoint is the last waypoint.
  bool get isLast => idx == count - 1;

  const RouteWaypointItem({this.onDelete, required this.waypoint, required this.idx, required this.count, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          if (isFirst)
            const StartIcon(width: 32, height: 32)
          else if (isLast)
            const DestinationIcon(width: 32, height: 32)
          else
            const WaypointIcon(width: 32, height: 32),

          const SmallHSpace(),

          Container(
            height: 42,
            width: frame.size.width - 114,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.all(Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const SmallHSpace(),
                Flexible(
                  child: BoldContent(
                    text: waypoint.address != null ? waypoint.address! : "Aktueller Standort",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    context: context,
                  ),
                ),
              ],
            ),
          ),

          const SmallHSpace(),

          // A button to remove the waypoint.
          if (onDelete != null)
            SizedBox(
              width: 42,
              height: 42,
              child: RawMaterialButton(
                elevation: 0,
                fillColor: Theme.of(context).colorScheme.surface,
                splashColor: Colors.black,
                onPressed: onDelete,
                shape: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DraggingWaypointItem extends RouteWaypointItem {
  final GlobalKey dragKey;

  const DraggingWaypointItem({
    required this.dragKey,
    required waypoint,
    required idx,
    required count,
    Key? key,
  }) : super(waypoint: waypoint, idx: idx, count: count, key: key);

  @override
  Widget build(BuildContext context) {
    return FractionalTranslation(
      translation: const Offset(-0.5, -0.5),
      child: ClipRRect(
        key: dragKey,
        borderRadius: BorderRadius.circular(12.0),
        child: Opacity(
          opacity: 0.85,
          child: super.build(context),
        ),
      ),
    );
  }
}

class RouteDetailsBottomSheetState extends State<RouteDetailsBottomSheet> {
  /// The associated routing service, which is injected by the provider.
  late Routing routingService;

  /// The associated position service, which is injected by the provider.
  late Positioning positioning;

  /// The associated status service, which is injected by the provider.
  late PredictionSGStatus status;

  @override
  void didChangeDependencies() {
    routingService = Provider.of<Routing>(context);
    positioning = Provider.of<Positioning>(context);
    status = Provider.of<PredictionSGStatus>(context);
    super.didChangeDependencies();
  }

  /// A callback that is executed when the order of the waypoints change.
  Future<void> onChangeWaypointOrder(int oldIndex, int newIndex) async {
    // Tell the tutorial that the user has changed the order of the waypoints.
    Provider.of<Tutorial>(context, listen: false).complete("priobike.tutorial.draw-waypoints");

    if (oldIndex == newIndex) return;
    if (routingService.selectedWaypoints == null || routingService.selectedWaypoints!.isEmpty) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final reorderedWaypoints = routingService.selectedWaypoints!.toList();
    final waypoint = reorderedWaypoints.removeAt(oldIndex);
    reorderedWaypoints.insert(newIndex, waypoint);

    routingService.selectWaypoints(reorderedWaypoints);
    routingService.loadRoutes(context);
  }

  /// A callback that is executed when the search page is opened.
  Future<void> onSearch() async {
    final bool showOwnLocationInSearch = routingService.selectedWaypoints != null ? true : false;
    final result = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => RouteSearch(showCurrentPositionAsWaypoint: showOwnLocationInSearch)));
    if (result == null) return;

    final waypoint = result as Waypoint;
    final waypoints = routingService.selectedWaypoints ?? [];

    // Add the own location as a start point to the route, if the waypoint selected in the search is the
    // first waypoint of the route. Thus making it the destination of the route.
    if (waypoints.isEmpty) {
      if (positioning.lastPosition != null) {
        waypoints.add(Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude));
      }
    }
    final newWaypoints = [...waypoints, waypoint];

    routingService.selectWaypoints(newWaypoints);
    routingService.loadRoutes(context);
  }

  /// A callback that is executed when the user removes a waypoint.
  Future<void> onRemoveWaypoint(int index) async {
    if (routingService.selectedWaypoints == null || routingService.selectedWaypoints!.isEmpty) return;

    final removedWaypoints = routingService.selectedWaypoints!.toList();
    removedWaypoints.removeAt(index);

    routingService.selectWaypoints(removedWaypoints);
    routingService.loadRoutes(context);
  }

  Widget renderDragIndicator(BuildContext context) {
    return Column(
      children: [
        Container(
          alignment: AlignmentDirectional.center,
          width: 32,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
          ),
        )
      ],
    );
  }

  Widget renderBottomSheetWaypoints(BuildContext context) {
    return Stack(
      children: [
        Row(
          children: [
            const SizedBox(width: 12),
            if (routingService.fetchedWaypoints != null)
              Column(
                children: [
                  const SizedBox(height: 36),
                  Stack(
                    alignment: AlignmentDirectional.center,
                    children: [
                      Container(
                          color: Theme.of(context).colorScheme.surface,
                          width: 16,
                          height: routingService.selectedWaypoints!.length * 42),
                      Container(
                          color: Theme.of(context).colorScheme.primary,
                          width: 8,
                          height: routingService.selectedWaypoints!.length * 42),
                    ],
                  ),
                ],
              ),
          ],
        ),
        Column(
          children: [
            LayoutBuilder(
              builder: ((context, constraints) {
                return ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  proxyDecorator: (proxyWidget, idx, anim) {
                    return proxyWidget;
                  },
                  onReorder: onChangeWaypointOrder,
                  children: routingService.selectedWaypoints?.asMap().entries.map<Widget>(
                        (entry) {
                          return RouteWaypointItem(
                            onDelete: () => onRemoveWaypoint(entry.key),
                            key: Key("$entry.key"),
                            count: routingService.selectedWaypoints?.length ?? 0,
                            idx: entry.key,
                            // Value is always a waypoint at this point
                            waypoint: entry.value,
                          );
                        },
                      ).toList() ??
                      [],
                );
              }),
            ),
            SearchWaypointItem(onSelect: onSearch),
          ],
        ),
      ],
    );
  }

  /// Render an info section on top of the bottom sheet.
  Widget renderTopInfoSection(BuildContext context) {
    if (routingService.selectedRoute == null) return Container();
    final distInfo = "${((routingService.selectedRoute!.path.distance) / 1000).toStringAsFixed(1)} km";
    final seconds = routingService.selectedRoute!.path.time / 1000;
    // Get the full hours needed to cover the route.
    final hours = seconds ~/ 3600;
    // Get the remaining minutes.
    final minutes = (seconds - hours * 3600) ~/ 60;
    // Calculate the time when the user will reach the destination.
    final arrivalTime = DateTime.now().add(Duration(seconds: seconds.toInt()));
    var text = "Zum Ziel";
    if (routingService.selectedProfile?.explanation != null) {
      text = routingService.selectedProfile!.explanation;
    }
    text += " - Grüne Welle auf ${(status.okPercentage * 100).toInt()}% der Strecke möglich";
    return Column(
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
        Content(
            text:
                "${hours == 0 ? '' : '$hours Std. '}$minutes Min. - Ankunft ${arrivalTime.hour}:${arrivalTime.minute.toString().padLeft(2, "0")} Uhr, $distInfo",
            context: context),
      ],
    );
  }

  /// Render the start ride button.
  Widget renderStartRideButton(BuildContext context) {
    if (routingService.selectedRoute == null) return Container();
    return BigButton(
      icon: Icons.pedal_bike,
      iconColor: Colors.white,
      label: "Losfahren",
      onPressed: widget.onSelectStartButton,
      boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
    );
  }

  /// Render the save route button.
  Widget renderSaveRouteButton(BuildContext context) {
    if (routingService.selectedRoute == null) return Container();
    return BigButton(
      icon: Icons.save,
      iconColor: Colors.white,
      label: "Strecke speichern",
      onPressed: widget.onSelectSaveButton,
      boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return SizedBox(
      height: frame.size.height, // Needed for reorderable list.
      child: DraggableScrollableSheet(
        initialChildSize: 124 / frame.size.height + (frame.padding.bottom / frame.size.height),
        maxChildSize: (frame.size.height - 86) / frame.size.height - (frame.padding.top / frame.size.height),
        minChildSize: 124 / frame.size.height + (frame.padding.bottom / frame.size.height),
        builder: (BuildContext context, ScrollController controller) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  renderDragIndicator(context),
                  const SizedBox(height: 4),
                  renderTopInfoSection(context),
                  const SizedBox(height: 4),
                  renderStartRideButton(context),
                  const SmallVSpace(),
                  renderBottomSheetWaypoints(context),
                  const TutorialView(
                    id: "priobike.tutorial.draw-waypoints",
                    text:
                        "Du kannst die Wegpunkte durch Ziehen neu anordnen. Durch langes Drücken auf die Karte kannst du direkt einen Wegpunkt platzieren.",
                    padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                  ),
                  const SizedBox(height: 2),
                  renderSaveRouteButton(context),
                  const VSpace(),
                  const SizedBox(height: 2),
                  const RouteHeightChart(),
                  const VSpace(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
