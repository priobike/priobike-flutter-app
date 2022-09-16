import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routingNew/services/routing.dart';
import 'package:priobike/routingNew/views/settings.dart';
import 'package:provider/provider.dart';

/// A view that displays alerts in the routing context.
class SearchBar extends StatefulWidget {
  const SearchBar({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SearchBarState();
}

class SearchBarState extends State<SearchBar> {
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
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24.0),
        bottomLeft: Radius.circular(24.0),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 0),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              bottomLeft: Radius.circular(24.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Icon(Icons.location_on),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SubHeader(
                    text: "Hier suchen",
                    context: context,
                    color: Colors.grey,
                  ),
                ),
              ),
              SmallIconButton(
                  icon: Icons.settings,
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const SettingsView()));
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
