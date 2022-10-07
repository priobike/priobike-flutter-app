import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/buttons.dart';
import 'package:provider/provider.dart';

import '../services/bottomSheetState.dart';

class BottomSheetDetail extends StatefulWidget {
  const BottomSheetDetail({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => BottomSheetDetailState();
}

class BottomSheetDetailState extends State<BottomSheetDetail> {
  late BottomSheetState bottomSheetState;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    bottomSheetState = Provider.of<BottomSheetState>(context);
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
        bottomSheetState.draggableScrollableController.size <= topSnapRatio - 0.05) {
      bottomSheetState.draggableScrollableController.animateTo(topSnapRatio,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic);
      return;
    }
    bottomSheetState.draggableScrollableController.animateTo(0.15,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic);
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
                            color: bottomSheetState.draggableScrollableController.size <=
                                topSnapRatio + 0.05 &&
                                bottomSheetState.draggableScrollableController.size >=
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
                      border: Border(
                        top: BorderSide(
                            width: 1,
                            color: Theme.of(context).colorScheme.surface),
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
