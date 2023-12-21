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
  final void Function()? onPressed;

  const YourBikeElementButton({
    super.key,
    required this.image,
    required this.title,
    this.color,
    this.backgroundColor,
    this.touchColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Tile(
          fill: backgroundColor ?? theme.colorScheme.background,
          splash: touchColor ?? theme.colorScheme.surfaceTint,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderColor:
              Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.all(8),
          borderWidth: 2,
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Transform.translate(
                      offset: Offset(0, MediaQuery.of(context).size.width * -0.02),
                      child: Transform.scale(
                        scale: 0.7,
                        child: image,
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, MediaQuery.of(context).size.width * 0.08),
                      child: Align(
                        alignment: Alignment.center,
                        child: Small(
                          text: title,
                          color: color ?? theme.colorScheme.primary,
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
  const YourBikeView({super.key});

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            crossAxisSpacing: 8,
            crossAxisCount: 3,
            children: [
              Theme.of(context).brightness == Brightness.light
                  ? YourBikeElementButton(
                      image: rentBikeActive
                          ? Image.asset("assets/images/rent-icon-white.png")
                          : Image.asset("assets/images/rent-icon-red.png"),
                      title: "Ausleihen",
                      color: rentBikeActive ? Colors.white : Theme.of(context).colorScheme.primary,
                      backgroundColor: rentBikeActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.background,
                      onPressed: toggleRentBikeSelection,
                    )
                  : YourBikeElementButton(
                      image: rentBikeActive
                          ? Image.asset("assets/images/rent-icon-red.png")
                          : Image.asset("assets/images/rent-icon-white.png"),
                      title: "Ausleihen",
                      color: rentBikeActive ? Theme.of(context).colorScheme.primary : Colors.white,
                      backgroundColor: rentBikeActive ? Colors.white : Theme.of(context).colorScheme.background,
                      onPressed: toggleRentBikeSelection,
                    ),
              Theme.of(context).brightness == Brightness.light
                  ? YourBikeElementButton(
                      image: pumpUpBikeActive
                          ? Image.asset("assets/icons/luftpumpe.png", color: Colors.white)
                          : Image.asset("assets/icons/luftpumpe.png"),
                      title: "Aufpumpen",
                      color: pumpUpBikeActive ? Colors.white : Theme.of(context).colorScheme.primary,
                      backgroundColor: pumpUpBikeActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.background,
                      onPressed: togglePumpUpBikeSelection,
                    )
                  : YourBikeElementButton(
                      image: pumpUpBikeActive
                          ? Image.asset("assets/icons/luftpumpe.png")
                          : Image.asset("assets/icons/luftpumpe.png", color: Colors.white),
                      title: "Aufpumpen",
                      color: pumpUpBikeActive ? Theme.of(context).colorScheme.primary : Colors.white,
                      backgroundColor: pumpUpBikeActive ? Colors.white : Theme.of(context).colorScheme.background,
                      onPressed: togglePumpUpBikeSelection,
                    ),
              Theme.of(context).brightness == Brightness.light
                  ? YourBikeElementButton(
                      image: repairBikeActive
                          ? Image.asset("assets/icons/werkzeug.png", color: Colors.white)
                          : Image.asset("assets/icons/werkzeug.png"),
                      title: "Reparieren",
                      color: repairBikeActive ? Colors.white : Theme.of(context).colorScheme.primary,
                      backgroundColor: repairBikeActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.background,
                      onPressed: toggleRepairBikeSelection,
                    )
                  : YourBikeElementButton(
                      image: repairBikeActive
                          ? Image.asset("assets/icons/werkzeug.png")
                          : Image.asset("assets/icons/werkzeug.png", color: Colors.white),
                      title: "Reparieren",
                      color: repairBikeActive ? Theme.of(context).colorScheme.primary : Colors.white,
                      backgroundColor: repairBikeActive ? Colors.white : Theme.of(context).colorScheme.background,
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
      {super.key, required this.rentBikeActive, required this.pumpUpBikeActive, required this.repairBikeActive});

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
          secondChild: NearbyResultsList(results: poi.rentalResults),
          crossFadeState: showList && widget.rentBikeActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        ),
        AnimatedCrossFade(
          firstCurve: Curves.easeInOutCubic,
          secondCurve: Curves.easeInOutCubic,
          sizeCurve: Curves.easeInOutCubic,
          duration: const Duration(milliseconds: 1000),
          firstChild: Container(),
          secondChild: NearbyResultsList(results: poi.bikeAirResults),
          crossFadeState: showList && widget.pumpUpBikeActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        ),
        AnimatedCrossFade(
          firstCurve: Curves.easeInOutCubic,
          secondCurve: Curves.easeInOutCubic,
          sizeCurve: Curves.easeInOutCubic,
          duration: const Duration(milliseconds: 1000),
          firstChild: Container(),
          secondChild: NearbyResultsList(results: poi.repairResults),
          crossFadeState: showList && widget.repairBikeActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        ),
      ],
    );
  }
}
