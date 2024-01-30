import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/routing.dart';

class POIInfo extends StatefulWidget {
  const POIInfo({super.key});

  @override
  POIInfoState createState() => POIInfoState();
}

class POIInfoState extends State<POIInfo> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    routing = getIt<Routing>();
    routing.addListener(update);
  }

  @override
  void dispose() {
    routing.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (routing.selectedPOI == null) return Container();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BoldContent(text: routing.selectedPOI!.name, context: context),
          const VSpace(),
          Content(
            text: routing.selectedPOI!.typeDescription,
            context: context,
          )
        ],
      ),
    );
  }
}
