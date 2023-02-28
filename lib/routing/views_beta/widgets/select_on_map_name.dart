import 'dart:async';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/home/models/place.dart';
import 'package:priobike/home/services/places.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';

class SelectOnMapNameView extends StatefulWidget {
  final Waypoint waypoint;

  const SelectOnMapNameView({Key? key, required this.waypoint}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SelectOnMapNameViewState();
}

class SelectOnMapNameViewState extends State<SelectOnMapNameView> {
  /// The associated profile service, which is injected by the provider.
  late Profile profile;

  /// The associated place service, which is injected by the provider.
  late Places places;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    profile = getIt<Profile>();
    profile.addListener(update);
    places = getIt<Places>();
    places.addListener(update);
  }

  @override
  void dispose() {
    profile.removeListener(update);
    places.removeListener(update);
    super.dispose();
  }

  /// A function that is executed when the complete button is pressed.
  Future<void> onComplete(BuildContext context, String name) async {
    Place newPlace = Place(waypoint: widget.waypoint, name: name);
    places.saveNewPlace(newPlace);

    if (widget.waypoint.address != null && profile.saveSearchHistory) {
      profile.saveNewSearch(widget.waypoint);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          SizedBox(
            width: frame.size.width,
            child: SafeArea(
              top: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Hero(
                        tag: 'appBackButton',
                        child: AppBackButton(
                            icon: Icons.chevron_left_rounded, onPressed: () => Navigator.pop(context), elevation: 5),
                      ),
                      const SizedBox(width: 16),
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
                            autofocus: true,
                            decoration: const InputDecoration(hintText: "Name", border: InputBorder.none),
                            onSubmitted: (name) {
                              if (name == "") {
                                ToastMessage.showError("Name darf nicht leer sein!");
                                return;
                              }
                              onComplete(context, name);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
