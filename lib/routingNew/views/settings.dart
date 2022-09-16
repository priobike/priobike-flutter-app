import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/ride/views/main.dart';
import 'package:priobike/ride/views/selection.dart';
import 'package:priobike/routingNew/services/geocoding.dart';
import 'package:priobike/routingNew/services/routing.dart';
import 'package:priobike/routingNew/views/map.dart';
import 'package:priobike/routingNew/services/mapcontroller.dart';
import 'package:priobike/routingNew/views/widgets/compassButton.dart';
import 'package:priobike/routingNew/views/widgets/filterButton.dart';
import 'package:priobike/routingNew/views/widgets/gpsButton.dart';
import 'package:priobike/routingNew/views/widgets/search_bar.dart';
import 'package:priobike/routingNew/views/widgets/shortcuts.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/ZoomInAndOutButton.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> {
  /// The associated shortcuts service, which is injected by the provider.
  ProfileService? profileService;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    profileService = Provider.of<ProfileService>(context);

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Hero(
                    tag: 'appBackButton',
                    child: AppBackButton(
                      icon: Icons.chevron_left_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: Center(
                        child: BoldSubHeader(
                          text: "Einstellungen",
                          context: context,
                        ),
                      ),
                    ),
                  ),

                  /// To center the text
                  const SizedBox(width: 80),
                ]),
                const SizedBox(height: 20),

                /// height = height - 20 - 88 - 20 - view.inset.top (padding, backButton, offset)
                SizedBox(
                  width: frame.size.width,
                  height: frame.size.height - 128,
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BoldContent(
                                text: "Allgemeine POIs anzeigen",
                                context: context),
                            Switch(value: true, onChanged: (value) {}),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BoldContent(
                                text: "Standort als Start setzen",
                                context: context),
                            Switch(value: true, onChanged: (value) {}),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BoldContent(
                                text: "Suchanfragen speichern",
                                context: context),
                            Switch(value: true, onChanged: (value) {}),
                          ],
                        ),
                      ),
                      InkWell(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          child:
                              BoldContent(text: "Meine Orte", context: context),
                        ),
                        onTap: () {
                          print("tapped on container");
                        },
                      ),
                      InkWell(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          child: BoldContent(
                              text: "Meine Routen", context: context),
                        ),
                        onTap: () {
                          print("tapped on container");
                        },
                      ),
                      InkWell(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          child: BoldContent(
                              text: "Suchhistorie löschen", context: context),
                        ),
                        onTap: () {
                          print("tapped on container");
                        },
                      ),
                      InkWell(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          child: BoldContent(
                              text: "Meine Orte löschen", context: context),
                        ),
                        onTap: () {
                          print("tapped on container");
                        },
                      ),
                      InkWell(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          child: BoldContent(
                              text: "Routen löschen", context: context),
                        ),
                        onTap: () {
                          print("tapped on container");
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
