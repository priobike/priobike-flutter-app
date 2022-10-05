import 'package:flutter/material.dart' hide Shortcuts;
import 'package:provider/provider.dart';

import '../services/bottomSheetState.dart';

class BottomSheetDetail extends StatefulWidget {
  const BottomSheetDetail({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => BottomSheetDetailState();
}

class BottomSheetDetailState extends State<BottomSheetDetail> {
  late BottomSheetState bottomSheet;

  DraggableScrollableController scrollController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    bottomSheet = Provider.of<BottomSheetState>(context);
    super.didChangeDependencies();
  }

  _onEndScroll(ScrollMetrics scrollMetrics, MediaQueryData frame) {
    // show routingBar if snapped to bottom
    if (scrollMetrics.viewportDimension > frame.size.height * 0.2) {
      bottomSheet.setNotShowRoutingBar();
    } else {
      bottomSheet.setShowRoutingBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return SizedBox(
      height: frame.size.height,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollEndNotification) {
            _onEndScroll(scrollNotification.metrics, frame);
          }
          return true;
        },
        child: DraggableScrollableSheet(
            initialChildSize: 0.15,
            minChildSize: 0.15,
            maxChildSize: 1,
            snap: true,
            snapSizes: const [0.5, 1],
            controller: scrollController,
            builder:
                (BuildContext buildContext, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: ListView(
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
                            color: Theme.of(context).colorScheme.background,
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
              );
            }),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
