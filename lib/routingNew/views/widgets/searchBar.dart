import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routingNew/services/routing.dart';
import 'package:priobike/routingNew/views/search.dart';
import 'package:priobike/routingNew/views/settings.dart';
import 'package:provider/provider.dart';

/// A view that displays alerts in the routing context.
class SearchBar extends StatefulWidget {
  final bool fromClicked;
  final TextEditingController? locationSearchController;

  const SearchBar({Key? key, required this.fromClicked, this.locationSearchController}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SearchBarState();
}

class SearchBarState extends State<SearchBar> {
  /// The associated routing service, which is injected by the provider.
  late Routing routingService;

  @override
  void didChangeDependencies() {
    routingService = Provider.of<Routing>(context);
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
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SearchView(),
              ),
            );
          },
          child: Stack(
            children: [
              Hero(
                tag: "searchBar",
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
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Hero(
                        tag: "locationIcon",
                        child: Icon(Icons.location_on),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: widget.fromClicked
                            ? TextField(
                                controller: widget.locationSearchController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                autofocus: widget.fromClicked,
                              )
                            : SubHeader(
                                text: "Hier suchen",
                                context: context,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    !widget.fromClicked
                        ? SmallIconButton(
                            icon: Icons.settings,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SettingsView(),
                                ),
                              );
                            })
                        : Container(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
