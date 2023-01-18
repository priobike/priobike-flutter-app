import 'dart:async';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routingNew/views/settings.dart';
import 'package:provider/provider.dart';

/// A view that displays the search bar.
class SearchBar extends StatefulWidget {
  final bool fromClicked;
  final Function startSearch;
  final TextEditingController? locationSearchController;

  const SearchBar({Key? key, required this.fromClicked, required this.startSearch, this.locationSearchController})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => SearchBarState();
}

class Debouncer {
  /// The preferred interval.
  final int milliseconds;

  /// The currently running timer.
  Timer? timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    timer?.cancel();
    timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class SearchBarState extends State<SearchBar> {
  /// The geosearch service that is injected by the provider.
  late Geosearch geosearch;

  /// The associated profile service, which is injected by the provider.
  late Profile profile;

  /// The associated position service, which is injected by the provider.
  late Positioning positioning;

  /// The currently fetched address.
  Waypoint? currentLocationWaypoint;

  /// The debouncer for the search.
  final debouncer = Debouncer(milliseconds: 100);

  @override
  void didChangeDependencies() {
    geosearch = Provider.of<Geosearch>(context);
    profile = Provider.of<Profile>(context);
    positioning = Provider.of<Positioning>(context);
    updateWaypoint();
    super.didChangeDependencies();
  }

  /// Update the waypoint.
  updateWaypoint() {
    if (positioning.lastPosition == null) {
      currentLocationWaypoint = null;
      return;
    }
    if (currentLocationWaypoint != null &&
        currentLocationWaypoint!.lat == positioning.lastPosition!.latitude &&
        currentLocationWaypoint!.lon == positioning.lastPosition!.longitude) return;
    currentLocationWaypoint = Waypoint(positioning.lastPosition!.latitude, positioning.lastPosition!.longitude);
  }

  /// A callback that is fired when the search is updated.
  Future<void> onSearchUpdated(String? query) async {
    if (query == null) return;
    debouncer.run(() {
      geosearch.geosearch(context, query);
    });
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
            if (!widget.fromClicked) {
              widget.startSearch();
            }
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
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                                onChanged: onSearchUpdated,
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    suffixIcon: widget.locationSearchController?.text != ""
                                        ? IconButton(
                                            onPressed: () {
                                              setState(() {
                                                geosearch.clearGeosearch();
                                                widget.locationSearchController?.text = "";
                                              });
                                            },
                                            icon: const Icon(Icons.cancel_outlined))
                                        : null),
                                autofocus: widget.fromClicked,
                              )
                            : Padding(
                                // Since new Font. FIXME
                                padding: const EdgeInsets.only(top: 5),
                                child: SubHeader(
                                  text: "Hier suchen",
                                  context: context,
                                  color: Colors.grey,
                                ),
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
