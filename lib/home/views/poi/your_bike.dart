import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/poi.dart';
import 'package:priobike/home/views/poi/nearby_poi_list.dart';
import 'package:priobike/main.dart';

class YourBikeView extends StatefulWidget {
  const YourBikeView({super.key});

  @override
  YourBikeViewState createState() => YourBikeViewState();
}

class YourBikeViewState extends State<YourBikeView> {
  /// The associated poi service, which is injected by the provider.
  late POI poi;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    poi = getIt<POI>();
    poi.addListener(update);

    // Fetch POI data
    poi.getRepairResults();
    poi.getRentalResults();
    poi.getBikeAirResults();
  }

  @override
  void dispose() {
    poi.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var metaText = "Lädt..";
    if (poi.errorDuringFetch) metaText = "Fehler beim Laden";
    if (poi.positionPermissionDenied) metaText = "Bitte Standortzugriff erlauben";
    Widget metaInformation = Padding(
      padding: const EdgeInsets.all(16),
      child: BoldContent(
        text: metaText,
        context: context,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );

    final showList = !poi.loading && !poi.errorDuringFetch && !poi.positionPermissionDenied;

    return Padding(
      padding: const EdgeInsets.only(left: 28, right: 28),
      child: Column(
        children: [
          showList
              ? Column(
                  children: [
                    NearbyResultsList(results: [
                      if (poi.rentalResults.isNotEmpty) poi.rentalResults.first,
                      if (poi.bikeAirResults.isNotEmpty) poi.bikeAirResults.first,
                      if (poi.repairResults.isNotEmpty) poi.repairResults.first,
                    ]),
                  ],
                )
              : metaInformation,
        ],
      ),
    );
  }
}
