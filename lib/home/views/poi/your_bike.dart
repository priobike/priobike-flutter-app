import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
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
  final void Function()? onPressed;

  const YourBikeElementButton({
    Key? key,
    required this.image,
    required this.title,
    this.color,
    this.backgroundColor,
    this.touchColor,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Tile(
          fill: backgroundColor ?? theme.colorScheme.background,
          splash: touchColor ?? CI.blue,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          padding: const EdgeInsets.all(8),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Transform.translate(
                      offset: Offset(0, MediaQuery.of(context).devicePixelRatio * 7),
                      child: Transform.scale(
                        scale: 1.25,
                        child: image,
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, MediaQuery.of(context).devicePixelRatio * 15),
                      child: Align(
                        alignment: Alignment.center,
                        child: Small(
                          text: title,
                          color: color ?? theme.colorScheme.onBackground,
                          textAlign: TextAlign.center,
                          context: context,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
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
  const YourBikeView({Key? key}) : super(key: key);

  @override
  YourBikeViewState createState() => YourBikeViewState();
}

class YourBikeViewState extends State<YourBikeView> {
  bool rentBikeActive = false;
  bool repairBikeActive = false;
  bool pumpUpBikeActive = false;

  void toggleRentBikeSelection() {
    final yourBikeService = getIt<POI>();
    yourBikeService.getRentalResults();
    setState(
      () {
        rentBikeActive = !rentBikeActive;
        repairBikeActive = false;
        pumpUpBikeActive = false;
      },
    );
  }

  void toggleRepairBikeSelection() {
    final yourBikeService = getIt<POI>();
    yourBikeService.getRepairResults();
    setState(
      () {
        rentBikeActive = false;
        repairBikeActive = !repairBikeActive;
        pumpUpBikeActive = false;
      },
    );
  }

  void togglePumpUpBikeSelection() {
    final yourBikeService = getIt<POI>();
    yourBikeService.getBikeAirResults();
    setState(
      () {
        rentBikeActive = false;
        repairBikeActive = false;
        pumpUpBikeActive = !pumpUpBikeActive;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HPad(
      child: Column(
        children: [
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            crossAxisSpacing: 8,
            crossAxisCount: 3,
            children: [
              YourBikeElementButton(
                image: rentBikeActive
                    ? Image.asset("assets/images/rent-light.png")
                    : Image.asset("assets/images/rent-dark.png"),
                title: "Ausleihen",
                color: rentBikeActive ? Colors.white : Theme.of(context).colorScheme.onBackground,
                backgroundColor:
                    rentBikeActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.background,
                onPressed: toggleRentBikeSelection,
              ),
              YourBikeElementButton(
                image: pumpUpBikeActive
                    ? Image.asset("assets/images/air-light.png")
                    : Image.asset("assets/images/air-dark.png"),
                title: "Aufpumpen",
                color: pumpUpBikeActive ? Colors.white : Theme.of(context).colorScheme.onBackground,
                backgroundColor:
                    pumpUpBikeActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.background,
                onPressed: togglePumpUpBikeSelection,
              ),
              YourBikeElementButton(
                image: repairBikeActive
                    ? Image.asset("assets/images/repair-light.png")
                    : Image.asset("assets/images/repair-dark.png"),
                title: "Reparieren",
                color: repairBikeActive ? Colors.white : Theme.of(context).colorScheme.onBackground,
                backgroundColor:
                    repairBikeActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.background,
                onPressed: toggleRepairBikeSelection,
              ),
            ],
          ),
          const SizedBox(height: 16),
          MetaListView(
            rentBikeActive: rentBikeActive,
            pumpUpBikeActive: pumpUpBikeActive,
            repairBikeActive: repairBikeActive,
          ),
        ],
      ),
    );
  }
}

class MetaListView extends StatefulWidget {
  final bool rentBikeActive;
  final bool pumpUpBikeActive;
  final bool repairBikeActive;

  const MetaListView(
      {Key? key, required this.rentBikeActive, required this.pumpUpBikeActive, required this.repairBikeActive})
      : super(key: key);

  @override
  MetaListViewState createState() => MetaListViewState();
}

class MetaListViewState extends State<MetaListView> {
  /// The associated poi service, which is injected by the provider.
  late POI poi;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();
    poi = getIt<POI>();
    poi.addListener(update);
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
        color: Theme.of(context).colorScheme.onBackground,
      ),
    );

    final showList = !poi.loading && !poi.errorDuringFetch && !poi.positionPermissionDenied;

    return Column(
      children: [
        AnimatedCrossFade(
          firstCurve: Curves.easeInOutCubic,
          secondCurve: Curves.easeInOutCubic,
          sizeCurve: Curves.easeInOutCubic,
          duration: const Duration(milliseconds: 1000),
          firstChild: Container(),
          secondChild: metaInformation,
          crossFadeState: !showList ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        ),
        AnimatedCrossFade(
          firstCurve: Curves.easeInOutCubic,
          secondCurve: Curves.easeInOutCubic,
          sizeCurve: Curves.easeInOutCubic,
          duration: const Duration(milliseconds: 1000),
          firstChild: Container(),
          secondChild: const NearbyRentResultsList(),
          crossFadeState: showList && widget.rentBikeActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        ),
        AnimatedCrossFade(
          firstCurve: Curves.easeInOutCubic,
          secondCurve: Curves.easeInOutCubic,
          sizeCurve: Curves.easeInOutCubic,
          duration: const Duration(milliseconds: 1000),
          firstChild: Container(),
          secondChild: const NearbyPumpUpResultsList(),
          crossFadeState: showList && widget.pumpUpBikeActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        ),
        AnimatedCrossFade(
          firstCurve: Curves.easeInOutCubic,
          secondCurve: Curves.easeInOutCubic,
          sizeCurve: Curves.easeInOutCubic,
          duration: const Duration(milliseconds: 1000),
          firstChild: Container(),
          secondChild: const NearbyRepairResultsList(),
          crossFadeState: showList && widget.repairBikeActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        ),
      ],
    );
  }
}