import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/services/poi.dart';
import 'package:priobike/home/views/poi/nearby_poi_list.dart';
import 'package:priobike/main.dart';

class YourBikeElementButton extends StatelessWidget {
  final Image image;
  final String title;
  final Color? color;
  final Color? backgroundColor;
  final Color? touchColor;
  final Color? borderColor;
  final void Function()? onPressed;

  const YourBikeElementButton({
    super.key,
    required this.image,
    required this.title,
    this.color,
    this.backgroundColor,
    this.touchColor,
    this.borderColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Tile(
          fill: backgroundColor ?? theme.colorScheme.surface,
          splash: touchColor ?? theme.colorScheme.surfaceTint,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderColor: borderColor ?? theme.colorScheme.primary,
          padding: const EdgeInsets.all(8),
          borderWidth: 4,
          shadowIntensity: 0.05,
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 2),
                // Resize image
                child: SizedBox(
                  width: constraints.maxWidth * 0.15,
                  height: constraints.maxWidth * 0.2,
                  child: image,
                ),
              ),
              Small(
                text: title,
                color: color ?? theme.colorScheme.primary,
                textAlign: TextAlign.center,
                context: context,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          onPressed: onPressed,
        );
      },
    );
  }
}

class YourBikeView extends StatefulWidget {
  const YourBikeView({super.key});

  @override
  YourBikeViewState createState() => YourBikeViewState();
}

class YourBikeViewState extends State<YourBikeView> {
  /// The associated poi service, which is injected by the provider.
  late POI poi;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

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
