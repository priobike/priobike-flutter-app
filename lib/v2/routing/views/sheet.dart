
import 'package:flutter/material.dart';
import 'package:priobike/v2/common/layout/buttons.dart';
import 'package:priobike/v2/common/layout/images.dart';
import 'package:priobike/v2/common/layout/spacing.dart';
import 'package:priobike/v2/common/layout/text.dart';
import 'package:priobike/v2/routing/services/routing.dart';
import 'package:provider/provider.dart';

/// A bottom sheet to display route details.
class RouteDetailsBottomSheet extends StatefulWidget {
  const RouteDetailsBottomSheet({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RouteDetailsBottomSheetState();
}

class RouteDetailsBottomSheetState extends State<RouteDetailsBottomSheet> {
  /// The associated routing service, which is injected by the provider.
  late RoutingService s;

  @override
  void didChangeDependencies() {
    s = Provider.of<RoutingService>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3, maxChildSize: 0.6,
      builder: (BuildContext context, ScrollController controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: ListView(
            controller: controller, 
            padding: const EdgeInsets.all(8), 
            children: [
              renderDragIndicator(context),
              const SmallVSpace(),
              renderBottomSheetWaypoints(context),
              const SmallVSpace(),
              BigButton(label: "Starten", onPressed: () {
                // TODO: Open ride view
              }),
            ],  
          ),
        );
      },
    );
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
    if (s.fetchedWaypoints == null) return Container();
    
    final frame = MediaQuery.of(context);
    return Stack(children: [
      Row(children: [
        const SizedBox(width: 12),
        Column(children: [
          const SizedBox(height: 8),
          Stack(alignment: AlignmentDirectional.center, children: [
            Container(color: const Color.fromARGB(255, 241, 241, 241), width: 16, height: s.fetchedWaypoints!.length * 32),
            Container(color: Colors.blueAccent, width: 8, height: s.fetchedWaypoints!.length * 32),
          ]),
        ]),
      ]),
      Column(children: s.fetchedWaypoints!.asMap().entries.map<Widget>((entry) {
        return Padding(
          padding: const EdgeInsets.all(4), 
          child: Row(children: [
            if (entry.key == 0) 
              const StartIcon(width: 32, height: 32)
            else if (entry.key == (s.fetchedWaypoints!.length - 1)) 
              const DestinationIcon(width: 32, height: 32) 
            else 
              const WaypointIcon(width: 32, height: 32),
            const SmallHSpace(),
            Container(
              height: 32, width: frame.size.width - 64,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 241, 241, 241),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(children: [
                const SmallHSpace(),
                Flexible(
                  child: BoldContent(
                    text: entry.value.address, 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                ),
              ]),
            ),
          ]),
        );
      }).toList()),
    ]);
  }
}
