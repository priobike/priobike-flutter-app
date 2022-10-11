import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/charts/height.dart';
import 'package:provider/provider.dart';

import '../services/bottomSheetState.dart';

final roadClassTranslation = {
  "motorway": "Autobahn",
  "trunk": "Fernstraße",
  "primary": "Hauptstraße",
  "secondary": "Landstraße",
  "tertiary": "???",
  "residential": "Wohnstraße",
  "unclassified": "Nicht klassifiziert",
  "service": "Zufahrtsstraße",
  "road": "Straße",
  "track": "Rennstrecke???",
  "bridleway": "Reitweg",
  "steps": "Treppen???",
  "cycleway": "Fahrradweg",
  "path": "Weg",
  "living_street": "Spielstraße",
  "footway": "Fußweg",
  "pedestrian": "Fußgängerzone",
  "platform": "Bahnsteig???",
  "corridor": "Korridor??",
  "other": "Sonstiges"
};

final roadClassColor = {
  "Autobahn": const Color(0xFF5B81FF),
  "Fernstraße": const Color(0xFF90A9FF),
  "Hauptstraße": const Color(0xFF3758FF),
  "Landstraße": const Color(0xFFACC7FF),
  "???": const Color(0xFFFFFFFF),
  "Wohnstraße": const Color(0xFFFFE4F8),
  "Nicht klassifiziert": const Color(0xFF686868),
  "Zufahrtsstraße": const Color(0xFF282828),
  "Straße": const Color(0xFF282828),
  "Rennstrecke???": const Color(0xFFB74093),
  "Reitweg": const Color(0xFF572B28),
  "Treppen???": const Color(0xFFB74093),
  "Fahrradweg": const Color(0xFF993D4C),
  "Weg": const Color(0xFF362626),
  "Spielstraße": const Color(0xFF1A4BFF),
  "Fußweg": const Color(0xFF8E8E8E),
  "Fußgängerzone": const Color(0xFF192765),
  "Bahnsteig???": const Color(0xFF2A0029),
  "Korridor??": const Color(0xFFB74093),
  "Sonstiges": const Color(0xFFB74093)
};

class BottomSheetDetail extends StatefulWidget {
  const BottomSheetDetail({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => BottomSheetDetailState();
}

class BottomSheetDetailState extends State<BottomSheetDetail> {
  /// The associated BottomSheetState, which is injected by the provider.
  late BottomSheetState bottomSheetState;

  /// The associated routingOLD service, which is injected by the provider.
  late Routing routing;

  /// The minimum bottom height of the bottomSheet
  static double bottomSnapRatio = 0.175;

  /// The details state of road class.
  bool showRoadClassDetails = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    bottomSheetState = Provider.of<BottomSheetState>(context);
    routing = Provider.of<Routing>(context);
    super.didChangeDependencies();
  }

  _changeDetailView(double topSnapRatio) {
    if (bottomSheetState.draggableScrollableController.size >= 0.14 &&
        bottomSheetState.draggableScrollableController.size <= 0.65) {
      bottomSheetState.draggableScrollableController.animateTo(0.66,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic);
      return;
    }
    if (bottomSheetState.draggableScrollableController.size >= 0.65 &&
        bottomSheetState.draggableScrollableController.size <=
            topSnapRatio - 0.05) {
      bottomSheetState.draggableScrollableController.animateTo(topSnapRatio,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic);
      return;
    }
    bottomSheetState.draggableScrollableController.animateTo(0.15,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic);
  }

  _detailRow(BuildContext context, String key, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Container(
            height: 20,
            width: 20,
            decoration: BoxDecoration(
                color: roadClassColor[key],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black)),
          ),
          const SizedBox(width: 10),
          Content(text: key, context: context),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Content(
                  text: value.toStringAsFixed(2) + "%", context: context),
            ),
          ),
        ],
      ),
    );
  }

  _barWithDetails(BuildContext context, Map<String, int> map, int max,
      MediaQueryData frame, bool expanded) {
    // Width - Padding.
    final double width = frame.size.width - 40;
    int mapIndex = 0;
    List<Widget> detailsList = [];
    List<Widget> containerList = [];
    for (var entry in map.entries) {
      Decoration decoration = BoxDecoration(
        border: const Border(
            top: BorderSide(color: Colors.black),
            bottom: BorderSide(color: Colors.black),
            right: BorderSide(color: Colors.black)),
        color: roadClassColor[entry.key],
      );
      if (mapIndex == 0) {
        decoration = BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
          color: roadClassColor[entry.key],
        );
      }
      if (mapIndex == map.length - 1) {
        decoration = BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: const BorderRadius.only(
              topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
          color: roadClassColor[entry.key],
        );
      }
      if (mapIndex == map.length - 2) {
        decoration = BoxDecoration(
          border: const Border(
            top: BorderSide(color: Colors.black),
            bottom: BorderSide(color: Colors.black),
          ),
          color: roadClassColor[entry.key],
        );
      }
      mapIndex++;
      containerList.add(Container(
        height: 40,
        width: width * (entry.value / max),
        decoration: decoration,
      ));
      detailsList
          .add(_detailRow(context, entry.key, (entry.value / max) * 100));
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          children: containerList,
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          firstChild: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            child: Column(
              children: detailsList,
            ),
          ),
          secondChild: Container(),
          crossFadeState: expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        ),
      ],
    );
  }

  _details(BuildContext context, MediaQueryData frame) {
    Map<String, int> roadClassMap = {};
    int roadClassMax = 0;
    if (routing.selectedRoute != null) {
      for (GHSegment<String> element
          in routing.selectedRoute!.path.details.roadClass) {
        if (element.value != null &&
            roadClassTranslation[element.value!] != null) {
          if (roadClassMap[roadClassTranslation[element.value!]!] != null) {
            roadClassMap[roadClassTranslation[element.value!]!] =
                roadClassMap[roadClassTranslation[element.value!]!]! +
                    element.to -
                    element.from;
            roadClassMax += element.to - element.from;
          } else {
            roadClassMap[roadClassTranslation[element.value!]!] =
                element.to - element.from;
            roadClassMax += element.to - element.from;
          }
        }
      }
    }
    return [
      Padding(
        padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 50),
        child: Column(
          children: [
            // Destination.
            routing.selectedWaypoints != null &&
                    routing.selectedWaypoints!.last.address != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: BoldSubHeader(
                      text: routing.selectedWaypoints!.last.address!,
                      context: context,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : Container(),
            const SizedBox(height: 5),
            // Important details.
            routing.selectedRoute != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Content(
                          text: ((routing.selectedRoute!.path.time * 0.001) *
                                      0.016)
                                  .round()
                                  .toString() +
                              " min",
                          context: context,
                          color: Colors.grey),
                      const SizedBox(width: 10),
                      Container(
                        height: 3,
                        width: 3,
                        decoration: const BoxDecoration(
                            color: Colors.grey, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Content(
                          text: (routing.selectedRoute!.path.distance * 0.001)
                                  .toStringAsFixed(2) +
                              " km",
                          context: context,
                          color: Colors.grey)
                    ],
                  )
                : Container(),
            const SizedBox(height: 10),
            // Route Environment
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              SubHeader(text: "Wegtypen", context: context),
              GestureDetector(
                onTap: () {
                  setState(() {
                    showRoadClassDetails = !showRoadClassDetails;
                  });
                },
                child: Row(children: [
                  Content(text: "Details", context: context),
                  const SizedBox(width: 5),
                  showRoadClassDetails
                      ? const Icon(Icons.keyboard_arrow_down_sharp)
                      : const Icon(Icons.keyboard_arrow_up_sharp)
                ]),
              ),
            ]),
            const SizedBox(height: 5),
            _barWithDetails(context, roadClassMap, roadClassMax, frame,
                showRoadClassDetails),
            const SizedBox(height: 10),
            // Route height profile
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              SubHeader(text: "Höhenprofil", context: context),
            ]),
            const RouteHeightChart(),
            // Route surface
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              SubHeader(text: "Oberflächentypen", context: context),
              SubHeader(text: "Details", context: context),
            ]),
            // Route instructions
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              SubHeader(text: "Anweisungen", context: context),
              SubHeader(text: "Details", context: context),
            ]),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    // Calculation: (height - 2 * Padding - appBackButtonHeight - systemBar) / Height.
    final double topSnapRatio =
        (frame.size.height - 25 - 64 - frame.padding.top) / frame.size.height;

    return SizedBox(
      height: frame.size.height,
      child: DraggableScrollableSheet(
          initialChildSize: bottomSnapRatio,
          minChildSize: bottomSnapRatio,
          maxChildSize: topSnapRatio,
          snap: true,
          snapSizes: const [0.66],
          controller: bottomSheetState.draggableScrollableController,
          builder:
              (BuildContext buildContext, ScrollController scrollController) {
            final bool isTop =
                bottomSheetState.draggableScrollableController.size <=
                        topSnapRatio + 0.05 &&
                    bottomSheetState.draggableScrollableController.size >=
                        topSnapRatio - 0.05;
            return AnimatedContainer(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(
                  top: isTop
                      ? const Radius.circular(0)
                      : const Radius.circular(20),
                ),
              ),
              duration: const Duration(milliseconds: 250),
              child: Stack(children: [
                ListView(
                  padding: const EdgeInsets.all(0),
                  controller: scrollController,
                  children: [
                    SizedBox(
                      height: 30,
                      child: Center(
                        child: AnimatedContainer(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isTop
                                ? Theme.of(context).colorScheme.surface
                                : Theme.of(context).colorScheme.background,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20),
                            ),
                          ),
                          duration: const Duration(milliseconds: 250),
                        ),
                      ),
                    ),
                    ...routing.selectedRoute != null
                        ? _details(context, frame)
                        : [],
                    const SizedBox(
                      height: 800,
                      width: 300,
                    )
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                            width: 1,
                            color: Theme.of(context).colorScheme.background),
                      ),
                    ),
                    width: frame.size.width,
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconTextButton(
                            onPressed: () {},
                            label: 'Starten',
                            icon: Icons.navigation),
                        IconTextButton(
                            onPressed: () {},
                            label: 'Speichern',
                            icon: Icons.save,
                            textColor: Theme.of(context).colorScheme.primary,
                            iconColor: Theme.of(context).colorScheme.primary,
                            borderColor: Theme.of(context).colorScheme.primary,
                            fillColor: Theme.of(context).colorScheme.surface),
                        IconTextButton(
                            onPressed: () => _changeDetailView(topSnapRatio),
                            label: isTop ? 'Karte' : 'Details',
                            icon: isTop ? Icons.map : Icons.list,
                            borderColor: Theme.of(context).colorScheme.primary,
                            textColor: Theme.of(context).colorScheme.primary,
                            iconColor: Theme.of(context).colorScheme.primary,
                            fillColor: Theme.of(context).colorScheme.surface)
                      ],
                    ),
                  ),
                ),
              ]),
            );
          }),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
