import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/images.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/charts/height.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:priobike/tutorial/view.dart';
import 'package:provider/provider.dart';

/// A bottom sheet to display route details.
class RouteDetailsBottomSheet extends StatefulWidget {
  /// A callback that is executed when the riding is started.
  final void Function() onSelectStartButton;

  /// A callback that is executed when a shortcut should be saved.
  final void Function() onSelectSaveButton;

  const RouteDetailsBottomSheet({
    required this.onSelectStartButton, 
    required this.onSelectSaveButton,
    Key? key
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => RouteDetailsBottomSheetState();
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

  const RouteWaypointItem({
    this.onDelete,
    required this.waypoint,
    required this.idx,
    required this.count,
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return Padding(
      padding: const EdgeInsets.all(4), 
      child: Row(children: [
        if (isFirst) const StartIcon(width: 32, height: 32)
        else if (isLast) const DestinationIcon(width: 32, height: 32) 
        else const WaypointIcon(width: 32, height: 32),

        const SmallHSpace(),

        Container(
          height: 32, width: frame.size.width - 104,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 241, 241, 241),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(children: [
            const SmallHSpace(),
            Flexible(
              child: BoldContent(
                text: waypoint.address, 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              ),
            ),
          ]),
        ),

        const SmallHSpace(),

        // A button to remove the waypoint.
        if (onDelete != null) SizedBox(
          width: 32,
          height: 32,
          child: RawMaterialButton(
            elevation: 0,
            fillColor: const Color.fromARGB(255, 241, 241, 241),
            splashColor: Colors.black,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                color: Colors.grey,
              ),
            ),
            onPressed: onDelete,
            shape: const CircleBorder(),
          ),
        ),
      ]),
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
  late RoutingService s;

  @override
  void didChangeDependencies() {
    s = Provider.of<RoutingService>(context);
    super.didChangeDependencies();
  }

  /// A callback that is executed when the order of the waypoints change.
  Future<void> onChangeWaypointOrder(int oldIndex, int newIndex) async {
    // Tell the tutorial that the user has changed the order of the waypoints.
    Provider.of<TutorialService>(context, listen: false).complete("priobike.tutorial.draw-waypoints");

    if (oldIndex == newIndex) return;
    if (s.selectedWaypoints == null || s.selectedWaypoints!.isEmpty) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final reorderedWaypoints = s.selectedWaypoints!.toList();
    final waypoint = reorderedWaypoints.removeAt(oldIndex);
    reorderedWaypoints.insert(newIndex, waypoint);

    s.selectWaypoints(reorderedWaypoints);
    s.loadRoutes(context);
  }

  /// A callback that is executed when the user removes a waypoint.
  Future<void> onRemoveWaypoint(int index) async {
    if (s.selectedWaypoints == null || s.selectedWaypoints!.isEmpty) return;

    final removedWaypoints = s.selectedWaypoints!.toList();
    removedWaypoints.removeAt(index);

    s.selectWaypoints(removedWaypoints);
    s.loadRoutes(context);
  }

  Widget renderDragIndicator(BuildContext context) {
    return Column(children: [
      Container(
        alignment: AlignmentDirectional.center, 
        width: 32, height: 6,
        decoration: const BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
      )
    ]);
  }

  Widget renderBottomSheetWaypoints(BuildContext context) {
    if (s.selectedWaypoints == null) return Container();
    
    return Stack(children: [
      Row(children: [
        const SizedBox(width: 12),
        Column(children: [
          const SizedBox(height: 8),
          Stack(alignment: AlignmentDirectional.center, children: [
            Container(color: const Color.fromARGB(255, 241, 241, 241), width: 16, height: s.fetchedWaypoints!.length * 32),
            Container(color: Colors.blueAccent, width: 8, height: s.selectedWaypoints!.length * 32),
          ]),
        ]),
      ]),
      LayoutBuilder(builder: ((context, constraints) {
        return ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          proxyDecorator: (proxyWidget, idx, anim) {
            return proxyWidget;
          },
          children: s.selectedWaypoints!.asMap().entries.map<Widget>((entry) {
            return RouteWaypointItem(
              onDelete: () => onRemoveWaypoint(entry.key),
              key: Key("$entry.key"),
              count: s.selectedWaypoints!.length,
              idx: entry.key,
              waypoint: entry.value,
            );
          }).toList(),
          onReorder: onChangeWaypointOrder,
        );
      })),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (s.selectedRoute == null || s.fetchedWaypoints == null) {
      return Positioned(
        bottom: 24, left: 24, right: 24,
        child: SafeArea(child: Tile(
          fill: Theme.of(context).colorScheme.background,
          content: Content(
            text: "Drücke lange auf die Karte, um eine Route zu zeichnen.",
          ),
        )),
      );
    }
    
    final distInfo = "${((s.selectedRoute!.path.distance) / 1000).toStringAsFixed(1)} km";
    final seconds = s.selectedRoute!.path.time / 1000;
    // Get the full hours needed to cover the route.
    final hours = seconds ~/ 3600;
    // Get the remaining minutes.
    final minutes = (seconds - hours * 3600) ~/ 60;
    // Calculate the time when the user will reach the destination.
    final arrivalTime = DateTime.now().add(Duration(seconds: seconds.toInt()));

    final frame = MediaQuery.of(context);

    return SizedBox(
      height: frame.size.height, // Needed for reorderable list.
      child: DraggableScrollableSheet(
        initialChildSize: 114 / frame.size.height + (frame.padding.bottom / frame.size.height), 
        maxChildSize: 1.0 - (frame.padding.top / frame.size.height),
        minChildSize: 114 / frame.size.height + (frame.padding.bottom / frame.size.height),
        builder: (BuildContext context, ScrollController controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
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
                  BoldContent(text: "Normalerweise ${hours == 0 ? '' : '$hours Std. '}$minutes Min.", color: Colors.green),
                  const SizedBox(height: 2),
                  Content(text: "Ankunft ${arrivalTime.hour}:${arrivalTime.minute.toString().padLeft(2, "0")} Uhr, $distInfo"),
                  const SizedBox(height: 4),
                  BigButton(
                    icon: Icons.pedal_bike,
                    label: "Losfahren", 
                    onPressed: widget.onSelectStartButton,
                    boxConstraints: BoxConstraints(minWidth: frame.size.width),
                  ),
                  const TutorialView(
                    id: "priobike.tutorial.draw-waypoints", 
                    text: "Du kannst die Wegpunkte durch Ziehen neu anordnen.",
                    padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                  ),
                  const SmallVSpace(),
                  renderBottomSheetWaypoints(context),
                  const SizedBox(height: 2),
                  const Divider(indent: 16, endIndent: 16),
                  const SizedBox(height: 2),
                  BigButton(
                    icon: Icons.save,
                    label: "Route speichern", 
                    onPressed: widget.onSelectSaveButton,
                    boxConstraints: BoxConstraints(minWidth: frame.size.width),
                  ),
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
