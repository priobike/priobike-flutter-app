import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:provider/provider.dart';

/// A view that displays alerts in the routing context.
class ZoomInAndOutButton extends StatefulWidget {
  const ZoomInAndOutButton({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ZoomInAndOutButtonState();
}

class ZoomInAndOutButtonState extends State<ZoomInAndOutButton> {
  /// The associated routing service, which is injected by the provider.
  late RoutingService routingService;

  @override
  void didChangeDependencies() {
    routingService = Provider.of<RoutingService>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      /// 32 + 2*10 padding
      height: 96,
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          elevation: 5,
          borderRadius: const BorderRadius.all(Radius.circular(25.0)),
          child: Container(
            width: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: const BorderRadius.all(Radius.circular(25.0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Icon(Icons.add),
                ),
                Container(
                  width: 40,
                  height: 1,
                  color: Theme.of(context).colorScheme.brightness ==
                          Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                const Expanded(
                  child: Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
