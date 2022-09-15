import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:provider/provider.dart';

/// A view that displays alerts in the routing context.
class GPSButton extends StatefulWidget {
  const GPSButton({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => GPSButtonState();
}

class GPSButtonState extends State<GPSButton> {
  /// The associated routing service, which is injected by the provider.
  late RoutingService routingService;

  @override
  void didChangeDependencies() {
    routingService = Provider.of<RoutingService>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: const BorderRadius.all(Radius.circular(24.0)),
      child: SmallIconButton(
        icon: Icons.gps_not_fixed,
        color: Theme.of(context).colorScheme.primary,
        onPressed: () {
          print("kompass");
        },
      ),
    );
  }
}
