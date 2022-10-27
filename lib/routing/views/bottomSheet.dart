import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/places.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/charts/height.dart';
import 'package:priobike/routing/views/instructions.dart';
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

final surfaceTranslation = {
  "asphalt": "Asphalt",
  "cobblestone": "Kopfsteinpflaster",
  "compacted": "Fester Boden",
  "concrete": "Beton",
  "dirt": "Erde",
  "fine_gravel": "Feiner Kies",
  "grass": "Graß",
  "gravel": "Kies",
  "ground": "Boden",
  "other": "Sonstiges",
  "paving_stones": "Pflastersteine",
  "sand": "Sand",
  "unpaved": "Unbefestigter Boden",
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

final surfaceColor = {
  "Asphalt": const Color(0xFF5B81FF),
  "Kopfsteinpflaster": const Color(0xFF688DFF),
  "Fester Boden": const Color(0xFF6E8EFA),
  "Beton": const Color(0xFF7394FF),
  "Erde": const Color(0xFF7F9EFF),
  "Feiner Kies": const Color(0xFFA1B7F8),
  "Graß": const Color(0xFFAFC3FF),
  "Kies": const Color(0xFFB6C5FA),
  "Boden": const Color(0xFFDEE5FD),
  "Sonstiges": const Color(0xFFF0F4FF),
  "Pflastersteine": const Color(0xFFFFFFFF),
  "Sand": const Color(0xFFC2C2C2),
  "Unbefestigter Boden": const Color(0xFFA0A0A0),
};

class BottomSheetDetail extends StatefulWidget {
  const BottomSheetDetail({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => BottomSheetDetailState();
}

class BottomSheetDetailState extends State<BottomSheetDetail> {
  /// The associated BottomSheetState, which is injected by the provider.
  late BottomSheetState bottomSheetState;

  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// The associated places service, which is injected by the provider.
  late Places places;

  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts shortcuts;

  /// The minimum bottom height of the bottomSheet
  static double bottomSnapRatio = 0.175;

  /// The details state of road class.
  bool showRoadClassDetails = false;

  /// The details state of surface.
  bool showSurfaceDetails = false;

  /// The details state of safety.
  bool showSafetyDetails = false;

  /// The state of saving route or place.
  bool showSaving = false;

  /// The name controller for saving a route or place.
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    bottomSheetState = Provider.of<BottomSheetState>(context);
    routing = Provider.of<Routing>(context);
    places = Provider.of<Places>(context);
    shortcuts = Provider.of<Shortcuts>(context);
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

    if (bottomSheetState.listController != null) {
      bottomSheetState.listController!.jumpTo(0);
    }
    bottomSheetState.draggableScrollableController.animateTo(0.15,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic);
  }

  _detailRow(BuildContext context, String key, double value,
      Map<String, Color> colorTranslation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Container(
            height: 20,
            width: 20,
            decoration: BoxDecoration(
                color: colorTranslation[key],
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

  _barWithDetails(
      BuildContext context,
      Map<String, int> map,
      int max,
      MediaQueryData frame,
      bool expanded,
      Map<String, Color> colorTranslation) {
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
        color: colorTranslation[entry.key],
      );
      if (mapIndex == 0) {
        decoration = BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
          color: colorTranslation[entry.key],
        );
      }
      if (mapIndex == map.length - 1) {
        decoration = BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: const BorderRadius.only(
              topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
          color: colorTranslation[entry.key],
        );
      }
      if (mapIndex == map.length - 2) {
        decoration = BoxDecoration(
          border: const Border(
            top: BorderSide(color: Colors.black),
            bottom: BorderSide(color: Colors.black),
          ),
          color: colorTranslation[entry.key],
        );
      }
      mapIndex++;
      containerList.add(Container(
        height: 40,
        width: width * (entry.value / max),
        decoration: decoration,
      ));
      detailsList.add(_detailRow(
          context, entry.key, (entry.value / max) * 100, colorTranslation));
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
          crossFadeState:
              expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        ),
      ],
    );
  }

  _dotRow(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Container(
          height: 10,
          width: 10,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Container(
          height: 10,
          width: 10,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Container(
          height: 10,
          width: 10,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  // The saveField widget used in details.
  _saveField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: BoldContent(context: context, text: 'Name'),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 20, right: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  bottomLeft: Radius.circular(25),
                ),
                border: Border.all(color: Colors.grey),
              ),
              child: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    hintText: "Name", border: InputBorder.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _details(BuildContext context, MediaQueryData frame) {
    // The roadClassMap, surfaceMap, roadClassMax and surfaceMax needed to display the surface- and roadClass bars.
    Map<String, int> roadClassMap = {};
    Map<String, int> surfaceMap = {};
    int roadClassMax = 0;
    int surfaceMax = 0;

    // Getting all roadClass elements.
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

      // Getting all surface elements.
      for (GHSegment<String> element
          in routing.selectedRoute!.path.details.surface) {
        if (element.value != null &&
            surfaceTranslation[element.value!] != null) {
          if (surfaceMap[surfaceTranslation[element.value!]!] != null) {
            surfaceMap[surfaceTranslation[element.value!]!] =
                surfaceMap[surfaceTranslation[element.value!]!]! +
                    element.to -
                    element.from;
            surfaceMax += element.to - element.from;
          } else {
            surfaceMap[surfaceTranslation[element.value!]!] =
                element.to - element.from;
            surfaceMax += element.to - element.from;
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
            // If in saving mode.
            showSaving ? _saveField(context) : Container(),
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
                  Content(
                    text: "Details",
                    context: context,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 5),
                  showRoadClassDetails
                      ? Icon(Icons.keyboard_arrow_down_sharp,
                          color: Theme.of(context).colorScheme.primary)
                      : Icon(Icons.keyboard_arrow_up_sharp,
                          color: Theme.of(context).colorScheme.primary)
                ]),
              ),
            ]),
            const SizedBox(height: 5),
            _barWithDetails(context, roadClassMap, roadClassMax, frame,
                showRoadClassDetails, roadClassColor),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                Icon(Icons.security,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 5),
                Content(text: "2,5", context: context),
                const SizedBox(width: 10),
                const Icon(Icons.traffic),
                Content(
                    text: routing.selectedRoute!.signalGroups.length
                        .toStringAsFixed(0),
                    context: context),
              ]),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showSafetyDetails = !showSafetyDetails;
                      });
                    },
                    child: Row(children: [
                      Content(
                        text: "Details",
                        context: context,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 5),
                      showSafetyDetails
                          ? Icon(
                              Icons.keyboard_arrow_down_sharp,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : Icon(
                              Icons.keyboard_arrow_up_sharp,
                              color: Theme.of(context).colorScheme.primary,
                            )
                    ]),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Safety Score"),
                          content: const Text(
                              "Die Werte des Safety Scores werden noch nicht erstellt und dienen nur der Optik."),
                          actions: [
                            TextButton(
                              child: const Text("Okay"),
                              onPressed: () => Navigator.of(context).pop(),
                            )
                          ],
                        ),
                      );
                    },
                  )
                ],
              )
            ]),
            const SizedBox(height: 5),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              firstChild: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.brightness ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black),
                  ),
                  width: frame.size.width,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BoldContent(text: "Verkehr", context: context),
                            _dotRow(context),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BoldContent(text: "Steigung", context: context),
                            _dotRow(context),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BoldContent(
                                text: "Gefahrenstellen", context: context),
                            _dotRow(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              secondChild: Container(),
              crossFadeState: showSafetyDetails
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
            ),
            const SizedBox(height: 20),
            // Route height profile
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              SubHeader(text: "Höhenprofil", context: context),
            ]),
            const RouteHeightChart(),
            // Route surface
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              SubHeader(text: "Oberflächentypen", context: context),
              GestureDetector(
                onTap: () {
                  setState(() {
                    showSurfaceDetails = !showSurfaceDetails;
                  });
                },
                child: Row(children: [
                  Content(
                    text: "Details",
                    context: context,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 5),
                  showSurfaceDetails
                      ? Icon(
                          Icons.keyboard_arrow_down_sharp,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Icon(
                          Icons.keyboard_arrow_up_sharp,
                          color: Theme.of(context).colorScheme.primary,
                        )
                ]),
              ),
            ]),
            const SizedBox(height: 5),
            _barWithDetails(context, surfaceMap, surfaceMax, frame,
                showSurfaceDetails, surfaceColor),
            const SizedBox(height: 10),
            // Route instructions
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Opens instruction page.
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InstructionsView(),
                  ),
                );
              },
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SubHeader(text: "Anweisungen", context: context),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  _lessDetails(BuildContext context, MediaQueryData frame) {
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
            const SizedBox(height: 35),
            Content(
              context: context,
              text:
                  "Hier Könnten noch einzelne Informationen zu einzelnen Wegpunkten angezeigt werden. Ist so im Konzept erstmal noch nicht vorgesehen.",
            )
          ],
        ),
      ),
    ];
  }

  _bottomButtons(bool isTop, double topSnapRatio) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconTextButton(
          onPressed: () {},
          label: 'Starten',
          icon: Icons.navigation,
          iconColor: Colors.white,
        ),
        IconTextButton(
            onPressed: () {
              setState(() {
                showSaving = true;
              });
            },
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
    );
  }

  _bottomButtonsSaving() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconTextButton(
          onPressed: () => _saveShortCut(),
          label: 'Speichern',
          icon: Icons.save,
          iconColor: Colors.white,
        ),
        IconTextButton(
            onPressed: () => {},
            label: 'Abbrechen',
            icon: Icons.cancel,
            borderColor: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.primary,
            iconColor: Theme.of(context).colorScheme.primary,
            fillColor: Theme.of(context).colorScheme.surface)
      ],
    );
  }

  _saveShortCut() {
    if (routing.selectedWaypoints != null) {
      // Save shortcut.
      if (routing.selectedWaypoints!.length > 1) {
        shortcuts.saveNewShortcut(nameController.text, context);
      } else {
        // Save place.
        if (routing.selectedWaypoints!.length == 1) {
          places.saveNewPlaceFromWaypoint(nameController.text, context);
        }
      }

    }
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
            // Set the listController once
            bottomSheetState.listController ??= scrollController;
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
                        : _lessDetails(context, frame),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
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
                      child: showSaving
                          ? _bottomButtonsSaving()
                          : _bottomButtons(isTop, topSnapRatio)),
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
