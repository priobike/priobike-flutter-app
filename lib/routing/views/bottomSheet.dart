import 'package:flutter/material.dart' hide Shortcuts;

class BottomSheetDetail extends StatefulWidget {
  const BottomSheetDetail({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => BottomSheetDetailState();
}

class BottomSheetDetailState extends State<BottomSheetDetail> {
  DraggableScrollableController scrollController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
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
          snapSizes: [0.5, 1],
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
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
