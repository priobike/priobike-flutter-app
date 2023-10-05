import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/confirm_button.dart';
import 'package:priobike/gamification/community_event/model/event.dart';
import 'package:priobike/gamification/community_event/model/location.dart';
import 'package:priobike/gamification/community_event/model/shortcut_event_location.dart';
import 'package:priobike/gamification/community_event/service/event_service.dart';
import 'package:priobike/gamification/community_event/views/badge.dart';
import 'package:priobike/home/models/shortcut.dart';
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
  late EventService _eventService;

  final ScrollController _scrollController = ScrollController();

  bool _selectionMode = false;

  bool _showCommunity = false;

  WeekendEvent? get _event => _eventService.event;

  List<EventLocation> get _locations => _eventService.locations;

  Map<EventLocation, bool> _mappedLocations = {};

  List<EventLocation> get _selectedLocations =>
      _mappedLocations.entries.where((e) => e.value).map((e) => e.key).toList();

  bool get _itemsSelected => _selectedLocations.isNotEmpty;

  int get _numOfSelected => _selectedLocations.length;

  @override
  void initState() {
    _eventService = getIt<EventService>();
    _eventService.addListener(update);
    _updateMappedLocations();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) => _eventService.fetchData());
    super.initState();
  }

  @override
  void dispose() {
    _eventService.removeListener(update);
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
          children: _mappedLocations.entries.map(
            (e) {
              var loc = e.key;
              var selected = e.value;
              var wasAchieved = _eventService.wasLocationAchieved(loc);
              var shortcut = ShortcutEventLocation(
                name: loc.title,
                achieved: wasAchieved,
                waypoint: Waypoint(
                  loc.lat,
                  loc.lon,
                  address: loc.title,
                ),
                id: 'unknown',
              );
              return Stack(
                children: [
                  ShortcutView(
                    selectionColor: CI.blue,
                    onLongPressed: wasAchieved
                        ? null
                        : () {
                            if (!_selectionMode) {
                              _selectionMode = !_selectionMode;
                              setState(() => _mappedLocations[loc] = !selected);
                            } else {
                              _mappedLocations[loc] = !selected;
                              setState(() {});
                            }
                          },
                    onPressed: wasAchieved
                        ? () {}
                        : () {
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
                  ),
                  if (wasAchieved)
                    Container(
                      width: shortcutWidth - 16,
                      height: shortcutHeight + 34,
                      decoration: BoxDecoration(
                        color: CI.blue.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.done_rounded,
                          color: CI.blue,
                          size: 96,
                        ),
                      ),
                    ),
                ],
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  Widget get confirmButton => Container(
        height: 64,
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
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ConfirmButton(
                    color: CI.blue,
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
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                    child: BoldSmall(
                      text: 'Du kannst auch mehrere Orte gleichzeitig auswählen, indem du ein Element gedrückt hältst.',
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
      value: Theme.of(context).brightness == Brightness.light
          ? SystemUiOverlayStyle.light.copyWith(
              systemNavigationBarColor: Theme.of(context).colorScheme.background,
              systemNavigationBarIconBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.dark,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              systemNavigationBarColor: Theme.of(context).colorScheme.background,
              systemNavigationBarIconBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.light,
            ),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: Column(
            children: [
              const SmallVSpace(),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  Text(
                    _event!.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'HamburgSans',
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 3,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _showCommunity = false),
                              child: Column(
                                children: [
                                  BoldSubHeader(
                                    text: 'Du',
                                    context: context,
                                    textAlign: TextAlign.center,
                                  ),
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _showCommunity
                                          ? Theme.of(context).colorScheme.onBackground.withOpacity(0.25)
                                          : CI.blue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _showCommunity = true),
                              child: Column(
                                children: [
                                  BoldSubHeader(
                                    text: 'Community',
                                    context: context,
                                    textAlign: TextAlign.center,
                                  ),
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _showCommunity
                                          ? CI.blue
                                          : Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SmallVSpace(),
                      if (_showCommunity) ...[
                        Expanded(child: Container()),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Icon(
                                  Icons.group,
                                  size: 56,
                                  color: CI.blue,
                                ),
                                Header(
                                  text: '${_eventService.numOfActiveUsers}',
                                  context: context,
                                  height: 1,
                                )
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 56,
                                  color: CI.blue,
                                ),
                                Header(
                                  text: '${_eventService.numOfAchievedLocations}',
                                  context: context,
                                  height: 1,
                                )
                              ],
                            ),
                          ],
                        ),
                        const SmallVSpace(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Content(
                            text: (_eventService.numOfActiveUsers == 0)
                                ? 'Du bist der erste, der dieses Wochenende am Stadtteil-Hopping teilnimmt!'
                                : 'Dieses Wochenende ${_eventService.numOfActiveUsers == 1 ? 'hat' : 'haben'} bereits ${_eventService.numOfActiveUsers} ${_eventService.numOfActiveUsers == 1 ? 'Person' : 'Personen'} am Stadtteil-Hopping teilgenommen. Dabei ${_eventService.numOfActiveUsers == 1 ? 'wurde 1 Ort' : 'wurden ${_eventService.numOfAchievedLocations} Orte'} in ${_event!.title} besucht.',
                            context: context,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(child: Container()),
                      ],
                      if (!_showCommunity) ...[
                        Expanded(child: Container()),
                        Center(
                          child: RewardBadge(
                            color: CI.blue,
                            size: 96,
                            iconIndex: _event!.iconValue,
                            achieved: _eventService.wasCurrentEventAchieved,
                          ),
                        ),
                        const SmallVSpace(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _eventService.wasCurrentEventAchieved
                              ? BoldSubHeader(
                                  text:
                                      'Super, du hast ${_event!.title} besucht und das dieswöchige Abzeichen erhalten!',
                                  context: context,
                                  textAlign: TextAlign.center,
                                )
                              : Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: CI.blue,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: BoldContent(
                                    text:
                                        'Besuche einen oder mehrere der unten aufgelisteten Orte in ${_event!.title} und hole dir das Abzeichen der Woche!',
                                    context: context,
                                    textAlign: TextAlign.center,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        Expanded(child: Container()),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.only(top: 8),
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
