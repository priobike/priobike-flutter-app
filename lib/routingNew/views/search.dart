import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/routingNew/services/geocoding.dart';
import 'package:priobike/routingNew/services/routing.dart';
import 'package:priobike/routingNew/services/mapcontroller.dart';
import 'package:priobike/routingNew/views/widgets/searchBar.dart';
import 'package:priobike/routingNew/views/widgets/shortcuts.dart';
import 'package:provider/provider.dart';

class SearchView extends StatefulWidget {
  const SearchView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SearchViewState();
}

class SearchViewState extends State<SearchView> {
  /// The associated geocoding service, which is injected by the provider.
  Geocoding? geocodingService;

  /// The associated routing service, which is injected by the provider.
  Routing? routingService;

  /// The associated shortcuts service, which is injected by the provider.
  Shortcuts? shortcutsService;

  /// The associated position service, which is injected by the provider.
  Positioning? positioning;

  /// The associated shortcuts service, which is injected by the provider.
  MapController? mapControllerService;

  /// The associated shortcuts service, which is injected by the provider.
  Profile? profileService;

  final TextEditingController _locationSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    geocodingService = Provider.of<Geocoding>(context);
    routingService = Provider.of<Routing>(context);
    shortcutsService = Provider.of<Shortcuts>(context);
    mapControllerService = Provider.of<MapController>(context);
    profileService = Provider.of<Profile>(context);
    positioning = Provider.of<Positioning>(context);

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
        body: Stack(children: [
          // Top Bar
          SafeArea(
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
                          elevation: 5),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      // Avoid expansion of alerts view.
                      width: frame.size.width - 80,
                      child: SearchBar(
                          fromClicked: true,
                          locationSearchController: _locationSearchController),
                    ),
                  ]),
                  const ShortCuts(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      width: frame.size.width,
                      height: 10,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  /// TODO hier letzte suchen
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
