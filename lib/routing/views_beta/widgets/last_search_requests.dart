import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routing/views_beta/widgets/waypoint_list_item_view.dart';

/// Widget for last search results
class LastSearchRequests extends StatefulWidget {
  final Function onWaypointTapped;
  final Function onCompleteSearch;
  final bool fromRouteSearch;

  const LastSearchRequests(
      {Key? key, required this.onWaypointTapped, required this.onCompleteSearch, required this.fromRouteSearch})
      : super(key: key);

  @override
  LastSearchRequestsState createState() => LastSearchRequestsState();
}

class LastSearchRequestsState extends State<LastSearchRequests> {
  /// The geosearch service that is injected by the provider.
  late Geosearch geosearch;

  /// The profile service that is injected by the provider.
  late Profile profile;

  /// Called when a listener callback of a ChangeNotifier is fired.
  late VoidCallback update;

  @override
  void initState() {
    super.initState();
    update = () => setState(() {});

    profile = getIt<Profile>();
    profile.addListener(update);
    geosearch = getIt<Geosearch>();
    geosearch.addListener(update);
  }

  @override
  void dispose() {
    profile.removeListener(update);
    geosearch.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Align(
          alignment: Alignment.centerLeft,
          child: BoldContent(text: "Letzte Suchen", context: context),
        ),
      ),
      if (profile.searchHistory?.isNotEmpty == true) ...[
        for (final waypoint in profile.searchHistory!) ...[
          WaypointListItemView(
              waypoint: waypoint,
              onTap: (waypoint) => widget.onWaypointTapped(waypoint),
              onCompleteSearch: (waypoint) => widget.onCompleteSearch(waypoint),
              fromRouteSearch: widget.fromRouteSearch),
        ]
      ]
    ]);
  }
}
