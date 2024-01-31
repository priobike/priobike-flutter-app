import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/services/routing_poi.dart';

class POIInfo extends StatefulWidget {
  const POIInfo({super.key});

  @override
  POIInfoState createState() => POIInfoState();
}

class POIInfoState extends State<POIInfo> {
  /// The associated routing service, which is injected by the provider.
  late RoutingPOI routingPOI;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    routingPOI = getIt<RoutingPOI>();
    routingPOI.addListener(update);
  }

  @override
  void dispose() {
    routingPOI.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (routingPOI.selectedPOI == null) return Container();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BoldContent(text: routingPOI.selectedPOI!.name, context: context),
          const VSpace(),
          Content(
            text: routingPOI.selectedPOI!.typeDescription,
            context: context,
          )
        ],
      ),
    );
  }
}
