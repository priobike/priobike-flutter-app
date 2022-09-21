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
  final ScrollController _scrollController1 = ScrollController();
  final ScrollController _scrollController2 = ScrollController();

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

  _leadingRoutingBarIcons(int max) {
    List<Widget> icons = [
      Icon(Icons.gps_fixed_outlined),
      Icon(Icons.more_vert),
      Icon(Icons.location_on)
    ];

    for (int i = 2; i <= max + 1; i++) {
      icons.insert(
        icons.length - 1,
        Container(
          width: 24,
          decoration: BoxDecoration(
              shape: BoxShape.circle, border: Border.all(color: Colors.white)),
          child: Center(
            child: Content(text: (i - 1).toString(), context: context),
          ),
        ),
      );
      icons.insert(
        icons.length - 1,
        Icon(Icons.more_vert),
      );
      print(icons);
    }

    return Column(
      children: icons,
    );
  }

  _routingBarRow(int index, int max) {
    IconData? leadingIcon;
    if (index == 0) leadingIcon = Icons.gps_fixed_outlined;
    if (index == max - 1) leadingIcon = Icons.location_on;

    IconData? trailingIcon;
    if (index < max - 1) trailingIcon = Icons.remove;
    if (index == max - 1) trailingIcon = Icons.add;

    return Row(
      key: Key('$index'),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              leadingIcon != null
                  ? Icon(leadingIcon)
                  : Container(
                      width: 24,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white)),
                      child: Center(
                        child:
                            Content(text: index.toString(), context: context),
                      ),
                    ),
              index < max - 1 ? Positioned(
                left: 3,
                top: index == 0 ? 23 : 20,
                child: const Icon(
                  Icons.more_vert,
                  size: 18,
                ),
              ) : Container(),
            ],
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
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
                    color: Theme.of(context).colorScheme.surface,
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
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: IconButton(
            constraints: const BoxConstraints(maxHeight: 40),
            iconSize: 20,
            icon: Icon(trailingIcon),
            onPressed: () {
              print("test");
            },
            splashRadius: 20,
          ),
        )
      ],
    );
  }

  @override
  void didChangeDependencies() {
    geosearch = Provider.of<Geosearch>(context);
    routingService = Provider.of<Routing>(context);
    super.didChangeDependencies();
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Material(
          elevation: 0,
          color: Colors.transparent,
          child: child,
        );
      },
      child: child,
    );
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: frame.size.height * 0.25,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: frame.size.height * 0.25,
                    ),
                    child: ReorderableListView(
                      padding: EdgeInsets.zero,
                      scrollController: _scrollController2,
                      proxyDecorator: _proxyDecorator,
                      // With a newer Version of Flutter onReorderStart can be used to hide symbols during drag
                      onReorder: (int oldIndex, int newIndex) {},
                      children: [
                        _routingBarRow(0, 2),
                        //_routingBarColumnDivider(),
                        _routingBarRow(1, 3),
                        //_routingBarColumnDivider(),
                        _routingBarRow(2, 4),
                        //_routingBarColumnDivider(),
                        _routingBarRow(3, 5),
                        //_routingBarColumnDivider(),
                        _routingBarRow(4, 6),
                        _routingBarRow(5, 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
