import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routingNew/services/geosearch.dart';
import 'package:priobike/routingNew/views/widgets/waypointListItemView.dart';
import 'package:provider/provider.dart';

/// Widget for last search results
class LastSearchRequests extends StatefulWidget {
  const LastSearchRequests({Key? key}) : super(key: key);

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Align(
          alignment: Alignment.centerLeft,
          child: BoldContent(text: "Letzte Suchen", context: context),
        ),
        if (profile.searchHistory?.isNotEmpty == true) ...[
          for (final waypoint in profile.searchHistory!) ...[
            WaypointListItemView(
                waypoint: waypoint,
                onTap: (waypoint) {},
                onCompleteSearch: (waypoint) {})
          ]
        ]
      ]),
    );
  }
}
