import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/places.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views_beta/widgets/details.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../routing/services/bottom_sheet_state.dart';

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

  /// The bool that holds the state of if the sheet is at the top.
  bool isTop = false;

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
  _changeDetailView(double topSnapRatio, MediaQueryData frame) {
    if (bottomSheetState.draggableScrollableController.isAttached) {
      // The bottom padding that has to be considered.
      final paddingBottom = 50 / frame.size.height;
      // Case details closed => move to 50%.
      if (bottomSheetState.draggableScrollableController.size >= 0.1 &&
          bottomSheetState.draggableScrollableController.size <= 0.65 - paddingBottom) {
        bottomSheetState.animateController(0.66 - paddingBottom);
        return;
      }
      // Case details 50% => move to fullscreen.
      if (bottomSheetState.draggableScrollableController.size >= 0.65 - paddingBottom &&
          bottomSheetState.draggableScrollableController.size <= topSnapRatio - 0.05) {
        bottomSheetState.animateController(topSnapRatio);
        return;
      }
      bottomSheetState.animateController(0.175 - paddingBottom);

      // Reset the second list.
      if (bottomSheetState.listController != null) {
        bottomSheetState.listController!.jumpTo(0);
      }
    }
  }

  /// The widget that displays the bottom buttons.
  _bottomButtons(bool isTop, double topSnapRatio, MediaQueryData frame) {
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
            onPressed: () => _changeDetailView(topSnapRatio, frame),
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
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          if (bottomSheetState.draggableScrollableController.isAttached) {
            if (bottomSheetState.draggableScrollableController.size <= topSnapRatio + 0.05 &&
                bottomSheetState.draggableScrollableController.size >= topSnapRatio - 0.05 &&
                isTop == false) {
              setState(() {
                isTop = true;
              });
            }
            if (bottomSheetState.draggableScrollableController.size <= topSnapRatio - 0.05 && isTop == true) {
              setState(() {
                isTop = false;
              });
            }
          }
          return false;
        },
        child: Column(
          children: [
            const Expanded(
              child: Details(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                border: const Border(
                  top: BorderSide(width: 1, color: Colors.grey),
                ),
              ),
              width: frame.size.width,
              height: 50,
              child: _bottomButtons(isTop, topSnapRatio, frame),
            ),
          ],
        ),
      ),
    );
  }
}
