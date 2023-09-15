import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/confirm_button.dart';
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

  Map<EventLocation, bool> _mappedLocations = {};

  bool _selectionMode = false;

  CommunityEvent? get _event => _communityService.event;

  List<EventLocation> get _locations => _communityService.locations;

  List<EventLocation> get _selectedLocations =>
      _mappedLocations.entries.where((e) => e.value).map((e) => e.key).toList();

  bool get _itemsSelected => _selectedLocations.isNotEmpty;

  int get _numOfSelected => _selectedLocations.length;

  @override
  void initState() {
    _communityService = getIt<CommunityService>();
    _communityService.addListener(update);
    _updateMappedLocations();
    super.initState();
  }

  @override
  void dispose() {
    _communityService.removeListener(update);
    super.dispose();
  }

  void _updateMappedLocations() {
    Map<EventLocation, bool> newMap = {};
    for (var loc in _locations) {
      newMap.addAll({loc: false});
    }
    for (var map in _mappedLocations.entries) {
      if (newMap[map.key] != null) {
        newMap[map.key] = map.value;
      }
    }
    _mappedLocations = newMap;
  }

  /// Called when a listener callback of a ChangeNotifier is fired
  void update() => {if (mounted) setState(_updateMappedLocations)};

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

  @override
  Widget build(BuildContext context) {
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
                    text: 'Statistiken',
                    context: context,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SmallVSpace(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _mappedLocations.entries.map(
                      (e) {
                        var foregroundColor = e.value ? Colors.white : Theme.of(context).colorScheme.onBackground;
                        return OnTapAnimation(
                          onPressed: _selectionMode
                              ? () {
                                  setState(() {
                                    _mappedLocations[e.key] = !e.value;
                                  });
                                }
                              : () {
                                  var shortcut = ShortcutLocation(
                                    name: 'unknown',
                                    waypoint: Waypoint(e.key.lat, e.key.lon, address: e.key.title),
                                    id: 'unknown',
                                  );
                                  _startRouteFromShortcut(shortcut);
                                },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: e.value ? CI.blue : Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
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
                  ),
                ),
              ),
              const SmallVSpace(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
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
                          _startRouteFromShortcut(shortcut);
                        }
                      : null,
                ),
              ),
              const SmallVSpace(),
            ],
          ),
        ),
      ),
    );
  }
}
