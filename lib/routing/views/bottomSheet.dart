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

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return SizedBox(
      height: frame.size.height,
      child: DraggableScrollableSheet(
          initialChildSize: 0.15,
          minChildSize: 0.15,
          maxChildSize: 1,
          snap: true,
          snapSizes: const [0.66, 1],
          controller: bottomSheetState.draggableScrollableController,
          builder:
              (BuildContext buildContext, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Stack(children: [
                ListView(
                  padding: const EdgeInsets.all(0),
                  controller: scrollController,
                  children: [
                    SizedBox(
                      height: 30,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20),
                            ),
                          ),
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
                        IconTextButton(onPressed: () {  }, label: 'Starten',),
                        IconTextButton(onPressed: () {  }, label: 'Speichern',),
                        IconTextButton(onPressed: () {  }, label: 'Details',)
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
