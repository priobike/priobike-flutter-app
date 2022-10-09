import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:provider/provider.dart';

import '../services/bottomSheetState.dart';

class BottomSheetDetail extends StatefulWidget {
  const BottomSheetDetail({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => BottomSheetDetailState();
}

class BottomSheetDetailState extends State<BottomSheetDetail> {
  /// The associated BottomSheetState, which is injected by the provider.
  late BottomSheetState bottomSheetState;

  /// The associated routingOLD service, which is injected by the provider.
  late Routing routing;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    bottomSheetState = Provider.of<BottomSheetState>(context);
    routing = Provider.of<Routing>(context);
    super.didChangeDependencies();
  }

  _changeDetailView(double topSnapRatio) {
    if (bottomSheetState.draggableScrollableController.size >= 0.14 &&
        bottomSheetState.draggableScrollableController.size <= 0.65) {
      bottomSheetState.draggableScrollableController.animateTo(0.66,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic);
      return;
    }
    if (bottomSheetState.draggableScrollableController.size >= 0.65 &&
        bottomSheetState.draggableScrollableController.size <=
            topSnapRatio - 0.05) {
      bottomSheetState.draggableScrollableController.animateTo(topSnapRatio,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic);
      return;
    }
    bottomSheetState.draggableScrollableController.animateTo(0.15,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic);
  }

  _details(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 50),
        child: Column(
          children: [
            // Destination.
            routing.selectedWaypoints != null &&
                    routing.selectedWaypoints!.last.address != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: BoldSubHeader(
                      text: routing.selectedWaypoints!.last.address!,
                      context: context,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : Container(),
            const SizedBox(height: 5),
            // Important details.
            routing.selectedRoute != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Content(
                          text: ((routing.selectedRoute!.path.time * 0.001) *
                                      0.016)
                                  .round()
                                  .toString() +
                              " min",
                          context: context,
                          color: Colors.grey),
                      const SizedBox(width: 10),
                      Container(
                        height: 3,
                        width: 3,
                        decoration: const BoxDecoration(
                            color: Colors.grey, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Content(
                          text: (routing.selectedRoute!.path.distance * 0.001)
                                  .toStringAsFixed(2) +
                              " km",
                          context: context,
                          color: Colors.grey)
                    ],
                  )
                : Container(),
            const SizedBox(height: 10),
            // Route Environment
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              SubHeader(text: "Wegtypen", context: context), SubHeader(text: "Details", context: context),
            ]),
            // Route height profile
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              SubHeader(text: "Höhenprofil", context: context), SubHeader(text: "Details", context: context),
            ]),
            // Route surface
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              SubHeader(text: "Oberflächentypen", context: context), SubHeader(text: "Details", context: context),
            ]),
            // Route instructions
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              SubHeader(text: "Anweisungen", context: context), SubHeader(text: "Details", context: context),
            ]),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    // Calculation: (height - 2 * Padding - appBackButtonHeight - systemBar) / Height.
    final double topSnapRatio =
        (frame.size.height - 25 - 64 - frame.padding.top) / frame.size.height;

    return SizedBox(
      height: frame.size.height,
      child: DraggableScrollableSheet(
          initialChildSize: 0.15,
          minChildSize: 0.15,
          maxChildSize: topSnapRatio,
          snap: true,
          snapSizes: const [0.66],
          controller: bottomSheetState.draggableScrollableController,
          builder:
              (BuildContext buildContext, ScrollController scrollController) {
            return AnimatedContainer(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(
                  top: bottomSheetState.draggableScrollableController.size <=
                              topSnapRatio + 0.05 &&
                          bottomSheetState.draggableScrollableController.size >=
                              topSnapRatio - 0.05
                      ? const Radius.circular(0)
                      : const Radius.circular(20),
                ),
              ),
              duration: const Duration(milliseconds: 250),
              child: Stack(children: [
                ListView(
                  padding: const EdgeInsets.all(0),
                  controller: scrollController,
                  children: [
                    SizedBox(
                      height: 30,
                      child: Center(
                        child: AnimatedContainer(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: bottomSheetState
                                            .draggableScrollableController
                                            .size <=
                                        topSnapRatio + 0.05 &&
                                    bottomSheetState
                                            .draggableScrollableController
                                            .size >=
                                        topSnapRatio - 0.05
                                ? Theme.of(context).colorScheme.surface
                                : Theme.of(context).colorScheme.background,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20),
                            ),
                          ),
                          duration: const Duration(milliseconds: 250),
                        ),
                      ),
                    ),
                    ...routing.selectedRoute != null ? _details(context) : [],
                    const SizedBox(
                      height: 800,
                      width: 300,
                    )
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                            width: 1,
                            color: Theme.of(context).colorScheme.background),
                      ),
                    ),
                    width: frame.size.width,
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconTextButton(
                            onPressed: () {},
                            label: 'Starten',
                            icon: Icons.navigation),
                        IconTextButton(
                            onPressed: () {},
                            label: 'Speichern',
                            icon: Icons.save,
                            textColor: Theme.of(context).colorScheme.primary,
                            iconColor: Theme.of(context).colorScheme.primary,
                            borderColor: Theme.of(context).colorScheme.primary,
                            fillColor: Theme.of(context).colorScheme.surface),
                        IconTextButton(
                            onPressed: () => _changeDetailView(topSnapRatio),
                            label: bottomSheetState
                                            .draggableScrollableController
                                            .size <=
                                        topSnapRatio + 0.05 &&
                                    bottomSheetState
                                            .draggableScrollableController
                                            .size >=
                                        topSnapRatio - 0.05
                                ? 'Karte'
                                : 'Details',
                            icon: bottomSheetState.draggableScrollableController
                                            .size <=
                                        topSnapRatio + 0.05 &&
                                    bottomSheetState
                                            .draggableScrollableController
                                            .size >=
                                        topSnapRatio - 0.05
                                ? Icons.map
                                : Icons.list,
                            borderColor: Theme.of(context).colorScheme.primary,
                            textColor: Theme.of(context).colorScheme.primary,
                            iconColor: Theme.of(context).colorScheme.primary,
                            fillColor: Theme.of(context).colorScheme.surface)
                      ],
                    ),
                  ),
                ),
              ]),
            );
          }),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
