import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/routing/services/geosearch.dart';
import 'package:priobike/routingNew/views/widgets/waypointListItemView.dart';
import 'package:provider/provider.dart';

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

  @override
  void didChangeDependencies() {
    geosearch = Provider.of<Geosearch>(context);
    profile = Provider.of<Profile>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
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
