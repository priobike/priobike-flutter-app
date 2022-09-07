import 'dart:async';

import 'package:flutter/material.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:provider/provider.dart';

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

/// A search page for waypoints.
class RouteSearch extends StatefulWidget {
  const RouteSearch({Key? key}) : super(key: key);

  @override
  RouteSearchState createState() => RouteSearchState();
}

class RouteSearchState extends State<RouteSearch> {
  /// The geosearch service that is injected by the provider.
  late GeosearchService geosearchService;

  /// The debouncer for the search.
  final debouncer = Debouncer(milliseconds: 400);

  @override
  void didChangeDependencies() {
    geosearchService = Provider.of<GeosearchService>(context);
    super.didChangeDependencies();
  }

  /// A callback that is fired when the search is updated.
  Future<void> onSearchUpdated(String? query) async {
    if (query == null) return;
    debouncer.run(() {
      geosearchService.geosearch(context, query);
    });
  }

  /// A callback that is fired when a waypoint is tapped.
  Future<void> onWaypointTapped(Waypoint waypoint) async {
    Navigator.of(context).pop(waypoint);
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    return Scaffold(body: SafeArea(child: Column(children: [
      Row(children: [
        AppBackButton(icon: Icons.chevron_left, onPressed: () => Navigator.pop(context)),
        const SmallHSpace(),
        Container(
          padding: const EdgeInsets.only(top: 16, bottom: 16),
          width: frame.size.width - 72,
          child: TextField(
            autofocus: true,
            onChanged: onSearchUpdated,
            decoration: const InputDecoration(
              hintText: "Suche",
              border: OutlineInputBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24))),
              suffixIcon: Icon(Icons.search),
            ),
          ),
        ),
      ]),
      Expanded(child: Fade(child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 16),
        itemCount: geosearchService.results?.length ?? 0,
        itemBuilder: (context, index) {
          return ListTile(
            title: BoldSmall(text: geosearchService.results![index].address, context: context),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => onWaypointTapped(geosearchService.results![index]),
          );
        },
      ))),
    ])));
  }
}