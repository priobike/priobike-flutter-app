import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/poi.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/status/services/sg.dart';

/// A list of POI elements.
class NearbyResultsList extends StatelessWidget {
  final List<POIElement> results;

  const NearbyResultsList({super.key, required this.results});

  /// A POI list element.
  Widget poiListElement(BuildContext context, POIElement poi) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        splashColor: Theme.of(context).colorScheme.surfaceTint,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onTap: () {
          HapticFeedback.mediumImpact();
          final waypoint = Waypoint(
            poi.lat,
            poi.lon,
            address: poi.name,
          );
          getIt<Routing>().selectWaypoints([waypoint]);
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoutingView())).then(
            (comingNotFromRoutingView) {
              if (comingNotFromRoutingView == null) {
                getIt<Routing>().reset();
                getIt<PredictionSGStatus>().reset();
              }
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 12, right: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: BoldSmall(
                      text: poi.name,
                      overflow: TextOverflow.ellipsis,
                      context: context,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SmallVSpace(),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Small(
                      text: poi.typeDescription,
                      overflow: TextOverflow.ellipsis,
                      context: context,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onTertiary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    if (poi.distance != null)
                      poi.distance! >= 1000
                          ? (BoldSmall(
                              text: "${(poi.distance! / 1000).toStringAsFixed(1)}km",
                              context: context,
                              color: Theme.of(context).colorScheme.tertiary))
                          : (BoldSmall(
                              text: "${poi.distance!.toStringAsFixed(0)}m",
                              context: context,
                              color: Theme.of(context).colorScheme.tertiary)),
                    Transform.translate(
                      offset: const Offset(2, 0),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: BoldContent(
          text: "Keine Ergebnisse",
          context: context,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.all(0),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: results.length,
        itemBuilder: (context, index) => poiListElement(
          context,
          results[index],
        ),
        separatorBuilder: (context, index) => const SizedBox(height: 4),
      ),
    );
  }
}
