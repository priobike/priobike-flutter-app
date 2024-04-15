import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';

/// A bottom sheet to display edit waypoint actions.
class EditWaypointBottomSheet extends StatefulWidget {
  const EditWaypointBottomSheet({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => EditWaypointBottomSheetState();
}

class EditWaypointBottomSheetState extends State<EditWaypointBottomSheet> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The scroll controller for the bottom sheet.
  late DraggableScrollableController controller;

  /// The initial child size of the bottom sheet.
  late double initialChildSize;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    routing = getIt<Routing>();
    routing.addListener(update);

    controller = DraggableScrollableController();
  }

  @override
  void dispose() {
    routing.removeListener(update);
    super.dispose();
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Column(children: [
              const SmallVSpace(),
              BoldContent(text: "Wegpunkt Bearbeiten", context: context),
              Small(
                text: "Du kannst den gewählten Wegpunkt durch Bewegen der Karte verschieben oder entfernen",
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
                  child: BigButtonTertiary(
                    label: "Abbrechen",
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    onPressed: routing.isFetchingRoute || routing.selectedRoute == null
                        ? null
                        : () => routing.unsetTappedWaypointIdx(),
                    addPadding: false,
                  ),
                ),
                const SmallHSpace(),
                Expanded(
                  child: BigButtonSecondary(
                    label: "Entfernen",
                    onPressed: routing.isFetchingRoute || routing.selectedRoute == null ? null : () => {},
                    addPadding: false,
                  ),
                ),
                const SmallHSpace(),
                Expanded(
                  child: BigButtonPrimary(
                    label: "Setzen",
                    onPressed: routing.isFetchingRoute || routing.selectedRoute == null ? null : () => {},
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
