import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/places.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/routing/views/details/height.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views_beta/instructions.dart';
import 'package:priobike/status/services/sg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../routing/services/bottom_sheet_state.dart';

/// The translation from of the road class.
final roadClassTranslation = {
  "motorway": "Autobahn",
  "trunk": "Fernstraße",
  "primary": "Hauptstraße",
  "secondary": "Landstraße",
  "tertiary": "Straße",
  "residential": "Wohnstraße",
  "unclassified": "Nicht klassifiziert",
  "service": "Zufahrtsstraße",
  "road": "Straße",
  "track": "Rennstrecke",
  "bridleway": "Reitweg",
  "steps": "Treppen",
  "cycleway": "Fahrradweg",
  "path": "Weg",
  "living_street": "Spielstraße",
  "footway": "Fußweg",
  "pedestrian": "Fußgängerzone",
  "platform": "Bahnsteig",
  "corridor": "Korridor",
  "other": "Sonstiges"
};

/// The translation of the surface.
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

/// The color translation of road class.
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
  "Rennstrecke": const Color(0xFFB74093),
  "Reitweg": const Color(0xFF572B28),
  "Treppen": const Color(0xFFB74093),
  "Fahrradweg": const Color(0xFF993D4C),
  "Weg": const Color(0xFF362626),
  "Spielstraße": const Color(0xFF1A4BFF),
  "Fußweg": const Color(0xFF8E8E8E),
  "Fußgängerzone": const Color(0xFF192765),
  "Bahnsteig": const Color(0xFF2A0029),
  "Korridor": const Color(0xFFB74093),
  "Sonstiges": const Color(0xFFB74093)
};

/// The color translation of the surface.
final surfaceColor = {
  "Asphalt": const Color(0xFF323232),
  "Kopfsteinpflaster": const Color(0xFF434849),
  "Fester Boden": const Color(0xFFEEB072),
  "Beton": const Color(0xFFBFBFBF),
  "Erde": const Color(0xFF402F22),
  "Feiner Kies": const Color(0xFF7B7B7B),
  "Graß": const Color(0xFF2B442F),
  "Kies": const Color(0xFFB6C5FA),
  "Boden": const Color(0xFFDEE5FD),
  "Sonstiges": const Color(0xFF00056D),
  "Pflastersteine": const Color(0xFF4C4C4C),
  "Sand": const Color(0xFFFFE74E),
  "Unbefestigter Boden": const Color(0xFF473E36),
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

  /// The associated sg status service, which is injected by the provider.
  late PredictionSGStatus predictionStatus;

  /// The minimum bottom height of the bottomSheet.
  static double bottomSnapRatio = 0.175;

  /// The details state of road class.
  bool showRoadClassDetails = false;

  /// The details state of surface.
  bool showSurfaceDetails = false;

  final _bottomSheetKey = GlobalKey<ScaffoldState>();

  DraggableScrollableController draggableScrollableController = DraggableScrollableController();

  bool isTop = false;

  @override
  void initState() {
    super.initState();
    draggableScrollableController.addListener(() {
      final frame = MediaQuery.of(context);
      // Calculation: ((height - 2 * Padding - appBackButtonHeight - systemBar) / Height) + close gap.
      final double topSnapRatio = ((frame.size.height - 25 - 64 - frame.padding.top) / frame.size.height) + 0.01;
      final size = draggableScrollableController.isAttached ? draggableScrollableController.size : 0;
      // Check if changed needed so that the drag animation does not get interrupted.
      if (isTop != (size <= topSnapRatio + 0.05 && size >= topSnapRatio - 0.05)) {
        setState(() {
          isTop = size <= topSnapRatio + 0.05 && size >= topSnapRatio - 0.05;
        });
      }
    });
  }

  /// Show a sheet to save the current route as a shortcut.
  void showSaveShortcutSheet() {
    final shortcuts = Provider.of<Shortcuts>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) {
        final nameController = TextEditingController();
        return AlertDialog(
          title: BoldContent(
              text:
                  'Bitte gib einen Namen an, unter dem ${routing.selectedWaypoints!.length == 1 ? "der Ort" : "die Strecke"} gespeichert werden soll.',
              context: context),
          content: SizedBox(
            height: 54,
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Heimweg, Zur Arbeit, ...'),
                ),
              ],
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final name = nameController.text;
                if (name.isEmpty) {
                  ToastMessage.showError("Name darf nicht leer sein.");
                }
                if (routing.selectedWaypoints != null) {
                  // Save shortcut.
                  if (routing.selectedWaypoints!.length > 1) {
                    await shortcuts.saveNewShortcut(nameController.text, context);
                  } else {
                    // Save place.
                    if (routing.selectedWaypoints!.length == 1) {
                      await places.saveNewPlaceFromWaypoint(nameController.text, context);
                    }
                  }
                }
                Navigator.pop(context);
              },
              child: BoldContent(text: 'Speichern', color: Theme.of(context).colorScheme.primary, context: context),
            ),
          ],
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    bottomSheetState = Provider.of<BottomSheetState>(context);
    routing = Provider.of<Routing>(context);
    places = Provider.of<Places>(context);
    shortcuts = Provider.of<Shortcuts>(context);
    predictionStatus = Provider.of<PredictionSGStatus>(context);
    super.didChangeDependencies();
  }

  /// A callback that is fired when the ride is started.
  Future<void> _onStartRide() async {
    // Check at least 2 waypoints.
    if (routing.selectedWaypoints != null && routing.selectedWaypoints!.length < 2) {
      ToastMessage.showError("Es sind zu wenig Wegpunkte ausgewählt.");
      return;
    }

    // We need to send a result (true) to inform the result handler in the HomeView that we do not want to reset
    // the services. This is only wanted when we pop the routing view in case of a back navigation (e.g. by back button)
    // from the routing view to the home view.
    void startRide() => Navigator.pushReplacement<void, bool>(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const RideView(),
        ),
        result: true);

    final preferences = await SharedPreferences.getInstance();
    final didViewWarning = preferences.getBool("priobike.routing.warning") ?? false;
    if (didViewWarning) {
      startRide();
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          alignment: AlignmentDirectional.center,
          actionsAlignment: MainAxisAlignment.center,
          title: BoldContent(
              text:
                  'Denke an deine Sicherheit und achte stets auf deine Umgebung. Beachte die Hinweisschilder und die örtlichen Gesetze.',
              context: context),
          content: Container(height: 0),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                preferences.setBool("priobike.routing.warning", true);
                startRide();
              },
              child: BoldContent(text: 'OK', color: Theme.of(context).colorScheme.primary, context: context),
            ),
          ],
        ),
      );
    }
  }

  /// The callback that is executed when the detail/map button is pressed.
  _changeDetailView(double topSnapRatio) {
    // Case details closed => move to 50%.
    if (draggableScrollableController.size >= 0.14 && draggableScrollableController.size <= 0.65) {
      bottomSheetState.animateController(0.66);
      return;
    }
    // Case details 50% => move to fullscreen.
    if (draggableScrollableController.size >= 0.65 && draggableScrollableController.size <= topSnapRatio - 0.05) {
      bottomSheetState.animateController(topSnapRatio);
      return;
    }
    bottomSheetState.animateController(0.175);

    // Reset the second list.
    if (bottomSheetState.listController != null) {
      bottomSheetState.listController!.jumpTo(0);
    }
  }

  /// The widget that displays a detail row in the bar.
  _detailRow(BuildContext context, String key, double value, Map<String, Color> colorTranslation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Container(
            height: 20,
            width: 20,
            decoration: BoxDecoration(
                color: colorTranslation[key], shape: BoxShape.circle, border: Border.all(color: Colors.black)),
          ),
          const SizedBox(width: 10),
          Content(text: key, context: context),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Content(text: "${value.toStringAsFixed(2)}%", context: context),
            ),
          ),
        ],
      ),
    );
  }

  /// The widget that displays a bar with details.
  _barWithDetails(BuildContext context, Map<String, int> map, int max, MediaQueryData frame, bool expanded,
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
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
          color: colorTranslation[entry.key],
        );
      }
      if (mapIndex == map.length - 1) {
        decoration = BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
          color: colorTranslation[entry.key],
        );
      }
      if (mapIndex == map.length - 2 && map.length > 2) {
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
      detailsList.add(_detailRow(context, entry.key, (entry.value / max) * 100, colorTranslation));
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

  /// The widget that displays the details.
  _details(BuildContext context, MediaQueryData frame) {
    // The roadClassMap, surfaceMap, roadClassMax and surfaceMax needed to display the surface- and roadClass bars.
    Map<String, int> roadClassMap = {};
    Map<String, int> surfaceMap = {};
    int roadClassMax = 0;
    int surfaceMax = 0;

    // Getting all roadClass elements.
    if (routing.selectedRoute != null) {
      for (GHSegment element in routing.selectedRoute!.path.details.roadClass) {
        if (element.value != null && roadClassTranslation[element.value!] != null) {
          if (roadClassMap[roadClassTranslation[element.value!]!] != null) {
            roadClassMap[roadClassTranslation[element.value!]!] =
                roadClassMap[roadClassTranslation[element.value!]!]! + element.to - element.from;
            roadClassMax += element.to - element.from;
          } else {
            roadClassMap[roadClassTranslation[element.value!]!] = element.to - element.from;
            roadClassMax += element.to - element.from;
          }
        }
      }

      // Getting all surface elements.
      for (GHSegment element in routing.selectedRoute!.path.details.surface) {
        if (element.value != null && surfaceTranslation[element.value!] != null) {
          if (surfaceMap[surfaceTranslation[element.value!]!] != null) {
            surfaceMap[surfaceTranslation[element.value!]!] =
                surfaceMap[surfaceTranslation[element.value!]!]! + element.to - element.from;
            surfaceMax += element.to - element.from;
          } else {
            surfaceMap[surfaceTranslation[element.value!]!] = element.to - element.from;
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
            routing.selectedWaypoints != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: BoldSubHeader(
                      text: routing.selectedWaypoints!.last.address ?? "Aktueller Standort",
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
                          text: "${((routing.selectedRoute!.path.time * 0.001) * 0.016).round()} min",
                          context: context,
                          color: Colors.grey),
                      const SizedBox(width: 10),
                      Container(
                        height: 3,
                        width: 3,
                        decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Content(
                          text: "${(routing.selectedRoute!.path.distance * 0.001).toStringAsFixed(2)} km",
                          context: context,
                          color: Colors.grey)
                    ],
                  )
                : Container(),
            const SizedBox(height: 25),
            // Route Environment
            GestureDetector(
              onTap: () {
                setState(() {
                  showRoadClassDetails = !showRoadClassDetails;
                });
              },
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                SubHeader(text: "Wegtypen", context: context),
                Row(children: [
                  Content(
                    text: "Details",
                    context: context,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 5),
                  showRoadClassDetails
                      ? Icon(Icons.keyboard_arrow_down_sharp, color: Theme.of(context).colorScheme.primary)
                      : Icon(Icons.keyboard_arrow_up_sharp, color: Theme.of(context).colorScheme.primary)
                ]),
              ]),
            ),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: () {
                setState(() {
                  showRoadClassDetails = !showRoadClassDetails;
                });
              },
              child: _barWithDetails(context, roadClassMap, roadClassMax, frame, showRoadClassDetails, roadClassColor),
            ),
            const SizedBox(height: 20),
            // Route height profile
            const RouteHeightChart(),
            // Route surface
            GestureDetector(
              onTap: () {
                setState(() {
                  showSurfaceDetails = !showSurfaceDetails;
                });
              },
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                SubHeader(text: "Oberflächentypen", context: context),
                Row(children: [
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
              ]),
            ),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: () {
                setState(() {
                  showSurfaceDetails = !showSurfaceDetails;
                });
              },
              child: _barWithDetails(context, surfaceMap, surfaceMax, frame, showSurfaceDetails, surfaceColor),
            ),
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

  /// The callback that is executed when less details button is pressed.
  _lessDetails(BuildContext context, MediaQueryData frame) {
    return [
      Padding(
        padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 50),
        child: Column(
          children: [
            // Destination.
            routing.selectedWaypoints != null
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
          ],
        ),
      ),
    ];
  }

  /// The widget that displays the bottom buttons.
  _bottomButtons(bool isTop, double topSnapRatio) {
    final double deviceWidth = WidgetsBinding.instance.window.physicalSize.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconTextButton(
          onPressed: _onStartRide,
          label: 'Starten',
          icon: Icons.navigation,
          iconColor: Colors.white,
        ),
        const SizedBox(width: 10),
        IconTextButton(
            onPressed: showSaveShortcutSheet,
            // Use abbreviation on smaller displays
            label: deviceWidth > 700 ? 'Speichern' : 'Sp.',
            icon: Icons.save,
            textColor: Theme.of(context).colorScheme.primary,
            iconColor: Theme.of(context).colorScheme.primary,
            borderColor: Theme.of(context).colorScheme.primary,
            fillColor: Theme.of(context).colorScheme.background),
        const SizedBox(width: 10),
        IconTextButton(
            onPressed: () => _changeDetailView(topSnapRatio),
            label: isTop ? 'Karte' : (deviceWidth > 700 ? 'Details' : 'Det.'),
            icon: isTop ? Icons.map : Icons.list,
            borderColor: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.primary,
            iconColor: Theme.of(context).colorScheme.primary,
            fillColor: Theme.of(context).colorScheme.background),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);
    // Calculation: ((height - 2 * Padding - appBackButtonHeight - systemBar) / Height) + close gap.
    final double topSnapRatio = ((frame.size.height - 25 - 64 - frame.padding.top) / frame.size.height) + 0.01;

    return SizedBox(
      height: frame.size.height,
      child: DraggableScrollableSheet(
          key: _bottomSheetKey,
          initialChildSize: bottomSheetState.initialHeight,
          minChildSize: bottomSnapRatio,
          maxChildSize: routing.selectedRoute != null ? topSnapRatio : bottomSnapRatio,
          snap: true,
          snapSizes: routing.selectedRoute != null ? [0.66] : [],
          controller: draggableScrollableController,
          builder: (BuildContext buildContext, ScrollController scrollController) {
            bottomSheetState.draggableScrollableController = draggableScrollableController;
            bottomSheetState.listController = scrollController;

            return AnimatedContainer(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.vertical(
                  top: isTop ? const Radius.circular(0) : const Radius.circular(20),
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
                            color: isTop ? Theme.of(context).colorScheme.background : Colors.grey,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20),
                            ),
                          ),
                          duration: const Duration(milliseconds: 250),
                        ),
                      ),
                    ),
                    ...routing.selectedRoute != null ? _details(context, frame) : _lessDetails(context, frame),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background,
                      border: const Border(
                        top: BorderSide(width: 1, color: Colors.grey),
                      ),
                    ),
                    width: frame.size.width,
                    height: 50,
                    child: _bottomButtons(isTop, topSnapRatio),
                  ),
                ),
              ]),
            );
          }),
    );
  }
}
