import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/poi.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/status/services/sg.dart';

Widget poiListIcon(BuildContext context, POIResult poi) {
  return Material(
    child: InkWell(
      splashColor: Theme.of(context).colorScheme.primary,
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
              getIt<Discomforts>().reset();
              getIt<PredictionSGStatus>().reset();
            }
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: BoldSmall(
                    text: poi.name,
                    overflow: TextOverflow.ellipsis,
                    context: context,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const SmallVSpace(),
                poi.distance >= 1000
                    ? (Small(text: "${(poi.distance / 1000).toStringAsFixed(1)} km von dir entfernt", context: context))
                    : (Small(text: "${poi.distance.toStringAsFixed(0)} m von dir entfernt", context: context)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.arrow_forward,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget nearbyResultsList(BuildContext context, List<POIResult> results) {
  return results.isEmpty
      ? Padding(
          padding: const EdgeInsets.all(16),
          child: BoldContent(
            text: "Lädt..",
            context: context,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        )
      : Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ListView.separated(
            padding: const EdgeInsets.all(0),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: results.length,
            itemBuilder: (context, index) => poiListIcon(
              context,
              results[index],
            ),
            separatorBuilder: (context, index) => const SizedBox(height: 10),
          ),
        );
}

class NearbyRentResultsList extends StatefulWidget {
  const NearbyRentResultsList({Key? key}) : super(key: key);

  @override
  NearbyRentResultsListState createState() => NearbyRentResultsListState();
}

class NearbyRentResultsListState extends State<NearbyRentResultsList> {
  /// The associated your bike service, which is injected by the provider.
  late POI yourBikeService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    yourBikeService = getIt<POI>();
    yourBikeService.addListener(update);
  }

  @override
  void dispose() {
    yourBikeService.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rentResults = yourBikeService.rentalResults;

    return nearbyResultsList(context, rentResults);
  }
}

class NearbyPumpUpResultsList extends StatefulWidget {
  const NearbyPumpUpResultsList({Key? key}) : super(key: key);

  @override
  NearbyPumpUpResultsListState createState() => NearbyPumpUpResultsListState();
}

class NearbyPumpUpResultsListState extends State<NearbyPumpUpResultsList> {
  /// The associated your bike service, which is injected by the provider.
  late POI yourBikeService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    yourBikeService = getIt<POI>();
    yourBikeService.addListener(update);
  }

  @override
  void dispose() {
    yourBikeService.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pumpUpResults = yourBikeService.bikeAirResults;

    return nearbyResultsList(context, pumpUpResults);
  }
}

class NearbyRepairResultsList extends StatefulWidget {
  const NearbyRepairResultsList({Key? key}) : super(key: key);

  @override
  NearbyRepairResultsListState createState() => NearbyRepairResultsListState();
}

class NearbyRepairResultsListState extends State<NearbyRepairResultsList> {
  /// The associated your bike service, which is injected by the provider.
  late POI yourBikeService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    yourBikeService = getIt<POI>();
    yourBikeService.addListener(update);
  }

  @override
  void dispose() {
    yourBikeService.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repairResults = yourBikeService.repairResults;

    return nearbyResultsList(context, repairResults);
  }
}
