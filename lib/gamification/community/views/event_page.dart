import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/confirm_button.dart';
import 'package:priobike/gamification/common/views/custom_dialog.dart';
import 'package:priobike/gamification/common/views/on_tap_animation.dart';
import 'package:priobike/gamification/community/model/event.dart';
import 'package:priobike/gamification/community/model/location.dart';
import 'package:priobike/gamification/community/service/community_service.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/models/waypoint.dart';
import 'package:priobike/routing/services/discomfort.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views/main.dart';
import 'package:priobike/status/services/sg.dart';

class CommunityEventPage extends StatefulWidget {
  const CommunityEventPage({Key? key}) : super(key: key);

  @override
  State<CommunityEventPage> createState() => _CommunityEventPageState();
}

class _CommunityEventPageState extends State<CommunityEventPage> {
  late CommunityService _communityService;

  CommunityEvent? get _event => _communityService.event;

  List<EventLocation> get _locations => _communityService.locations;

  @override
  void initState() {
    _communityService = getIt<CommunityService>();
    _communityService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _communityService.removeListener(update);
    super.dispose();
  }

  /// Called when a listener callback of a ChangeNotifier is fired
  void update() => {if (mounted) setState(() {})};

  void _startRouteFromShortcut(Shortcut shortcut) {
    final shortcutIsValid = shortcut.isValid();
    if (!shortcutIsValid) {
      //showInvalidShortcutSheet(context);
      return;
    }
    // Select shortcut for routing.
    getIt<Routing>().selectShortcut(shortcut);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoutingView())).then(
      (comingNotFromRoutingView) {
        if (comingNotFromRoutingView == null) {
          getIt<Routing>().reset();
          getIt<Discomforts>().reset();
          getIt<PredictionSGStatus>().reset();
        }
      },
    );
  }

  Widget get _participantCounter => SizedBox(
        height: 64,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(child: Container()),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(
                    Icons.directions_bike,
                    color: CI.blue,
                    size: 32,
                  ),
                ),
                const SmallHSpace(),
                BoldSubHeader(
                  text: '0',
                  context: context,
                ),
              ],
            ),
            Expanded(child: Container()),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_event == null) return Container();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: Column(
            children: [
              const SmallVSpace(),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 0.5,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: AppBackButton(
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const HSpace(),
                  SubHeader(
                    text: _event!.title,
                    context: context,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SmallVSpace(),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BoldContent(text: _communityService.numOfAchievedLocations.toString(), context: context),
                  IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => LocationSelection(
                            locations: _locations,
                            startRoute: _startRouteFromShortcut,
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.star,
                        size: 56,
                      ))
                ],
              ),
              const SmallVSpace(),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SmallVSpace(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: BoldContent(
                                text: 'Zielpunkte:',
                                context: context,
                                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                        ..._locations.map(
                          (loc) {
                            return OnTapAnimation(
                              scaleFactor: 0.95,
                              onPressed: () {
                                var shortcut = ShortcutLocation(
                                  name: 'unknown',
                                  waypoint: Waypoint(loc.lat, loc.lon, address: loc.title),
                                  id: 'unknown',
                                );
                                _startRouteFromShortcut(shortcut);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.background,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    const Icon(
                                      Icons.place,
                                      size: 32,
                                    ),
                                    Expanded(
                                      child: SubHeader(
                                        text: loc.title,
                                        context: context,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LocationSelection extends StatefulWidget {
  final Function(Shortcut) startRoute;

  final List<EventLocation> locations;

  const LocationSelection({Key? key, required this.locations, required this.startRoute}) : super(key: key);

  @override
  State<LocationSelection> createState() => _LocationSelectionState();
}

class _LocationSelectionState extends State<LocationSelection> {
  Map<EventLocation, bool> _mappedLocations = {};

  List<EventLocation> get _selectedLocations =>
      _mappedLocations.entries.where((e) => e.value).map((e) => e.key).toList();

  bool get _itemsSelected => _selectedLocations.isNotEmpty;

  int get _numOfSelected => _selectedLocations.length;

  @override
  void initState() {
    _updateMappedLocations();
    super.initState();
  }

  /// Called when a listener callback of a ChangeNotifier is fired
  void update() => {if (mounted) setState(_updateMappedLocations)};

  void _updateMappedLocations() {
    Map<EventLocation, bool> newMap = {};
    for (var loc in widget.locations) {
      newMap.addAll({loc: false});
    }
    for (var map in _mappedLocations.entries) {
      if (newMap[map.key] != null) {
        newMap[map.key] = map.value;
      }
    }
    _mappedLocations = newMap;
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      content: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          BoldSubHeader(text: 'Wähle deine Zielpunkte', context: context),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: ConfirmButton(
              label: _itemsSelected ? 'Route anzeigen ($_numOfSelected)' : 'Zielpunkte auswählen',
              onPressed: _itemsSelected
                  ? () {
                      var waypoints = _selectedLocations
                          .map((loc) => Waypoint(
                                loc.lat,
                                loc.lon,
                                address: loc.title,
                              ))
                          .toList();
                      var shortcut = ShortcutRoute(
                        name: 'unknown',
                        waypoints: waypoints,
                        id: 'unknown',
                      );
                      widget.startRoute(shortcut);
                    }
                  : null,
            ),
          ),
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ..._mappedLocations.entries.map(
                    (e) {
                      var foregroundColor = e.value ? Colors.white : Theme.of(context).colorScheme.onBackground;
                      return OnTapAnimation(
                        scaleFactor: 0.95,
                        onPressed: () {
                          setState(() {
                            _mappedLocations[e.key] = !e.value;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: e.value ? CI.blue : Theme.of(context).colorScheme.background,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Icon(
                                e.value ? Icons.done : Icons.place,
                                size: 32,
                                color: foregroundColor,
                              ),
                              Expanded(
                                child: SubHeader(
                                  text: e.key.title,
                                  context: context,
                                  textAlign: TextAlign.center,
                                  color: foregroundColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ).toList(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
