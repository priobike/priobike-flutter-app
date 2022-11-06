import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/places.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/routing/views/places.dart';
import 'package:priobike/routing/views/routes.dart';
import 'package:priobike/routing/views/widgets/deleteDialog.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> {
  /// The associated profile service, which is injected by the provider.
  late Profile profile;

  /// The associated shortcuts service, which is injected by the provider.
  late Places places;

  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts shortcuts;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    profile = Provider.of<Profile>(context);
    places = Provider.of<Places>(context);
    shortcuts = Provider.of<Shortcuts>(context);

    super.didChangeDependencies();
  }

  _deleteSearchHistory() {
    profile.searchHistory = [];
    profile.store();
    ToastMessage.showSuccess("Suchhistorie gelöscht!");
  }

  _deleteAllPlaces() {
    places.updatePlaces([], context);
    ToastMessage.showSuccess("Orte gelöscht!");
  }

  _deleteAllRoutes() {
    shortcuts.updateShortcuts([], context);
    ToastMessage.showSuccess("Routen gelöscht!");
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
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
                Expanded(
                  child: ListView(
                    children: [
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(
                      //       horizontal: 20, vertical: 10),
                      //   child: Row(
                      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //     children: [
                      //       BoldContent(
                      //           text: "Allgemeine POIs anzeigen",
                      //           context: context),
                      //       Switch(
                      //           value: profile.showGeneralPOIs,
                      //           onChanged: (value) {
                      //             setState(() {
                      //               profile.showGeneralPOIs = value;
                      //               profile.store();
                      //             });
                      //           }),
                      //     ],
                      //   ),
                      // ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BoldContent(text: "Standort als Start setzen", context: context),
                            Switch(
                                value: profile.setLocationAsStart,
                                onChanged: (value) {
                                  setState(() {
                                    profile.setLocationAsStart = value;
                                    profile.store();
                                  });
                                }),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BoldContent(text: "Suchanfragen speichern", context: context),
                            Switch(
                                value: profile.saveSearchHistory,
                                onChanged: (value) {
                                  setState(() {
                                    profile.saveSearchHistory = value;
                                    profile.store();
                                  });
                                }),
                          ],
                        ),
                      ),
                      InkWell(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: BoldContent(text: "Meine Orte", context: context),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PlacesView(),
                            ),
                          );
                        },
                      ),
                      InkWell(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: BoldContent(text: "Meine Routen", context: context),
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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: BoldContent(text: "Suchhistorie löschen", context: context),
                        ),
                        onTap: () {
                          showDeleteDialog(context, "Suchanfragen", _deleteSearchHistory);
                        },
                      ),
                      InkWell(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: BoldContent(text: "Meine Orte löschen", context: context),
                        ),
                        onTap: () {
                          showDeleteDialog(context, "Orte", _deleteAllPlaces);
                        },
                      ),
                      InkWell(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: BoldContent(text: "Routen löschen", context: context),
                        ),
                        onTap: () {
                          showDeleteDialog(context, "Routen", _deleteAllRoutes);
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
