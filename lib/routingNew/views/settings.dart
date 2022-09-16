import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/routingNew/views/locations.dart';
import 'package:priobike/routingNew/views/routes.dart';
import 'package:provider/provider.dart';

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
                            Switch(
                                value: profileService?.showGeneralPOIs ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    profileService?.showGeneralPOIs = value;
                                    profileService?.store();
                                  });
                                }),
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
                            Switch(
                                value:
                                    profileService?.setLocationAsStart ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    profileService?.setLocationAsStart = value;
                                    profileService?.store();
                                  });
                                }),
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
                            Switch(
                                value:
                                    profileService?.saveSearchHistory ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    profileService?.saveSearchHistory = value;
                                    profileService?.store();
                                  });
                                }),
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
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LocationsView(),
                            ),
                          );
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
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RoutesView(),
                            ),
                          );
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
