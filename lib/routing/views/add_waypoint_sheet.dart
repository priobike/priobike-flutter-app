import 'dart:io';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/images.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/map_functions.dart';
import 'package:priobike/routing/services/routing.dart';

/// A bottom sheet to display edit waypoint actions.
class AddWaypointBottomSheet extends StatefulWidget {
  /// The associated map functions service, which is injected by the provider.
  final MapFunctions mapFunctions;

  const AddWaypointBottomSheet({
    super.key,
    required this.mapFunctions,
  });

  @override
  State<StatefulWidget> createState() => AddWaypointBottomSheetState();
}

class AddWaypointBottomSheetState extends State<AddWaypointBottomSheet> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The scroll controller for the bottom sheet.
  late DraggableScrollableController controller;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    routing = getIt<Routing>();
    routing.addListener(update);
    widget.mapFunctions.addListener(update);

    controller = DraggableScrollableController();
  }

  @override
  void dispose() {
    routing.removeListener(update);
    widget.mapFunctions.removeListener(update);
    super.dispose();
  }

  void _setWaypoint() {
    widget.mapFunctions.getCoordinatesForWaypoint();
  }

  void _cancel() {
    widget.mapFunctions.unsetSelectPointOnMap();
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return SizedBox(
      height: 118 + frame.padding.bottom,
      width: frame.size.width,
      child: Stack(children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 0, blurRadius: 16)],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Column(children: [
              const SmallVSpace(),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SmallHSpace(),
                    Padding(
                      padding: EdgeInsets.only(top: Platform.isAndroid ? 4 : 0),
                      child: BoldContent(text: "Wegpunkt Hinzufügen", context: context),
                    ),
                    const SmallHSpace(),
                    const StartIcon(width: 20, height: 20),
                  ]),
              const SizedBox(
                height: 4,
              ),
              Small(
                text: "Du kannst den Wegpunkt durch Bewegen der Karte platzieren und hinzufügen.",
                context: context,
                textAlign: TextAlign.center,
              )
            ]),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            width: frame.size.width,
            height: frame.padding.bottom + 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SmallHSpace(),
                Expanded(
                  child: BigButtonTertiary(
                    label: "Abbrechen",
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    onPressed: routing.isFetchingRoute ? null : _cancel,
                    addPadding: false,
                  ),
                ),
                const SmallHSpace(),
                Expanded(
                  child: BigButtonPrimary(
                    label: "Hinzufügen",
                    onPressed: routing.isFetchingRoute ? null : _setWaypoint,
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
