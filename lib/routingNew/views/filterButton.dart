import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:provider/provider.dart';

/// A view that displays alerts in the routing context.
class FilterButton extends StatefulWidget {
  const FilterButton({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => FilterButtonState();
}

class FilterButtonState extends State<FilterButton> {
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
      height: 64,
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          elevation: 5,
          borderRadius: const BorderRadius.all(Radius.circular(24.0)),
          child: SmallIconButton(
            icon: Icons.filter_alt_rounded,
            onPressed: () {
              print("filter");
            },
          ),
        ),
      ),
    );
  }
}
