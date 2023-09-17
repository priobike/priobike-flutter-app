import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/confirm_button.dart';
import 'package:priobike/gamification/common/views/custom_dialog.dart';
import 'package:priobike/gamification/common/views/on_tap_animation.dart';
import 'package:priobike/gamification/community/model/event.dart';
import 'package:priobike/gamification/community/model/location.dart';
import 'package:priobike/gamification/community/service/community_service.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_location.dart';
import 'package:priobike/home/models/shortcut_route.dart';
import 'package:priobike/home/views/shortcuts/selection.dart';
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

  final ScrollController _scrollController = ScrollController();

  bool _selectionMode = false;

  CommunityEvent? get _event => _communityService.event;

  List<EventLocation> get _locations => _communityService.locations;

  Map<EventLocation, bool> _mappedLocations = {};

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

  /// Called when a listener callback of a ChangeNotifier is fired
  void update() => {if (mounted) setState(_updateMappedLocations)};

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
        setState(() {});
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

  Widget get locationSelection {
    const double shortcutRightPad = 16;
    final shortcutWidth = (MediaQuery.of(context).size.width / 2) - shortcutRightPad;
    final shortcutHeight = max(shortcutWidth - (shortcutRightPad * 3), 128.0);
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: _mappedLocations.entries.map((e) {
            var loc = e.key;
            var selected = e.value;
            var shortcut = ShortcutLocation(
              name: loc.title,
              waypoint: Waypoint(
                loc.lat,
                loc.lon,
                address: loc.title,
              ),
              id: 'unknown',
            );
            return ShortcutView(
              onLongPressed: () => setState(() {
                if (!_selectionMode) {
                  _selectionMode = !_selectionMode;
                  setState(() => _mappedLocations[loc] = !selected);
                } else {
                  _mappedLocations[loc] = !selected;
                  setState(() {});
                }
              }),
              onPressed: () {
                if (_selectionMode) {
                  _mappedLocations[loc] = !selected;
                  if (!_itemsSelected) {
                    _selectionMode = !_selectionMode;
                  }
                  setState(() {});
                } else {
                  _startRouteFromShortcut(shortcut);
                }
              },
              shortcut: shortcut,
              width: shortcutWidth,
              height: shortcutHeight,
              rightPad: shortcutRightPad,
              selected: selected,
              showSplash: false,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget get confirmButton => Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AnimatedSwitcher(
          switchInCurve: Curves.easeIn,
          duration: const ShortDuration(),
          reverseDuration: const Duration(milliseconds: 100),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0)).animate(animation),
            child: child,
          ),
          child: (_selectionMode)
              ? Padding(
                  key: const ValueKey('ConfirmButton'),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ConfirmButton(
                    label: 'Route anzeigen ($_numOfSelected)',
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
                            for (var e in _mappedLocations.entries) {
                              _mappedLocations[e.key] = false;
                            }
                            _selectionMode = false;
                          }
                        : null,
                  ),
                )
              : Center(
                  key: const ValueKey('InfoText'),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: BoldSmall(
                      text: 'Erstelle eine Route über mehrere Standorte, indem du ein Element lange gedrückt hältst.',
                      context: context,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
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
                ],
              ),
              Expanded(child: Container()),
              Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    locationSelection,
                    confirmButton,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
