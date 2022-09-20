import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routingNew/services/geosearch.dart';
import 'package:priobike/routingNew/services/routing.dart';
import 'package:priobike/routingNew/views/search.dart';
import 'package:provider/provider.dart';

/// A view that displays alerts in the routing context.
class RoutingBar extends StatefulWidget {
  final TextEditingController? locationSearchController;

  const RoutingBar({Key? key, this.locationSearchController}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RoutingBarState();
}

class RoutingBarState extends State<RoutingBar> {
  /// The geosearch service that is injected by the provider.
  late Geosearch geosearch;

  /// The associated routing service, which is injected by the provider.
  late Routing routingService;

  /// The divider for Elements in the RoutingBar
  _routingBarColumnDivider() {
    return SizedBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 1,
            width: 30,
            child: Stack(clipBehavior: Clip.none, children: const [
              Positioned(
                left: 0,
                top: -11,
                child: Icon(Icons.more_vert),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  _routingBarRow(int index, int max) {
    IconData? leadingIcon;
    if (index == 0) leadingIcon = Icons.gps_fixed_outlined;
    if (index == max - 1) leadingIcon = Icons.location_on;

    return Row(
      children: [
        leadingIcon != null
            ? Icon(leadingIcon)
            : Container(
                width: 24,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white)),
                child: Center(
                  child: Content(text: index.toString(), context: context),
                ),
              ),
        const SizedBox(width: 5),
        Expanded(
          child: SizedBox(
            height: 40,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SearchView(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.only(left: 20, right: 5),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    bottomLeft: Radius.circular(25),
                  ),
                  border: Border.all(color: Colors.grey),
                ),
                child: Center(
                  child: Content(
                      text: routingService.selectedWaypoints![0].address
                          .toString(),
                      context: context,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.swap_vert),
          onPressed: () => {},
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    geosearch = Provider.of<Geosearch>(context);
    routingService = Provider.of<Routing>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    return Material(
      elevation: 5,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        width: frame.size.width,
        child: SafeArea(
          top: true,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Hero(
                tag: 'appBackButton',
                child: AppBackButton(
                    icon: Icons.chevron_left_rounded,
                    onPressed: () {
                      routingService.reset();
                    },
                    elevation: 5),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  children: [
                    _routingBarRow(0, 2),
                    _routingBarColumnDivider(),
                    _routingBarRow(1, 3),
                    _routingBarColumnDivider(),
                    _routingBarRow(2, 3),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
