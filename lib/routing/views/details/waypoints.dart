import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/images.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/routing/models/waypoint.dart';

class SearchWaypointItem extends StatelessWidget {
  /// A callback that is executed when the waypoint is selected.
  final void Function()? onSelect;

  const SearchWaypointItem({this.onSelect, super.key});

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const AddWaypointIcon(width: 32, height: 32),
          const SmallHSpace(),
          SizedBox(
            height: 42,
            width: frame.size.width - 106,
            child: Tile(
              fill: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
              onPressed: onSelect,
              showShadow: false,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              content: Row(
                children: [
                  Flexible(
                    child: BoldContent(
                      color: Theme.of(context).colorScheme.tertiary,
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
          if (onSelect != null)
            SizedBox(
              width: 42,
              height: 42,
              child: SmallIconButtonPrimary(
                icon: Icons.search,
                onPressed: onSelect!,
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

  const RouteWaypointItem({this.onDelete, required this.waypoint, required this.idx, required this.count, super.key});

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (isFirst)
            const StartIcon(width: 32, height: 32)
          else if (isLast)
            const DestinationIcon(width: 32, height: 32)
          else
            Stack(
              alignment: Alignment.center,
              children: [
                const WaypointIcon(width: 32, height: 32),
                BoldContent(
                  text: (idx + 1).toString(),
                  color: Colors.black,
                  context: context,
                )
              ],
            ),

          const SmallHSpace(),

          Container(
            height: 42,
            width: frame.size.width - 106,
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
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
              child: SmallIconButtonTertiary(icon: Icons.close, onPressed: onDelete!),
            ),
        ],
      ),
    );
  }
}
