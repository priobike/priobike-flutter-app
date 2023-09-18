import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/colors.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/confirm_button.dart';
import 'package:priobike/gamification/common/views/custom_dialog.dart';
import 'package:priobike/gamification/common/views/on_tap_animation.dart';
import 'package:priobike/gamification/community/model/event.dart';
import 'package:priobike/gamification/community/model/location.dart';
import 'package:priobike/gamification/community/service/community_service.dart';
import 'package:priobike/gamification/community/views/badge.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/models/shortcut_event_location.dart';
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
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) => _communityService.fetchCommunityEventData());
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
              var wasAchieved = _communityService.wasLocationAchieved(loc);
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
                    selectionColor: _event!.color,
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
                      height: shortcutHeight + 40,
                      decoration: BoxDecoration(
                        color: _event!.color.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.shield,
                          color: _event!.color,
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
                    color: _event!.color,
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
                      text:
                          'Du kannst auch mehrere Locations gleichzeitig auswählen, indem du ein Element gedrückt hältst.',
                      context: context,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
        ),
      );

  Widget get _helpDialog => CustomDialog(
        backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.95),
        horizontalMargin: 16,
        content: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BoldSubHeader(text: 'Weekend-Events', context: context),
                const SmallVSpace(),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: SubHeader(
                        text:
                            'Jedes Wochenende finden individuelle Weekend-Events, mit unterschiedlichen Themengebieten statt. Mit dem Event kommen eine Reihe von thematisch passenden Standorten. Für jeden dieser Standorte kannst du ein Event-spezifisches Abzeichen erlangen, indem du mithilfe der Navigationsfunktion an ihnen vorbeifährst.',
                        context: context,
                        textAlign: TextAlign.center,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            )),
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
                  Expanded(child: Container()),
                  IconButton(
                    onPressed: () => showDialog(context: context, builder: (context) => _helpDialog),
                    icon: const Icon(Icons.question_mark, size: 48),
                  ),
                  const SmallHSpace(),
                ],
              ),
              const SmallVSpace(),
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
              const SmallVSpace(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Content(
                  text:
                      'Fahr dieses Wochenende doch einfach mal durch die Grünstreifen der Stadt und genieß das gute Wetter!',
                  context: context,
                  textAlign: TextAlign.center,
                ),
              ),
              const VSpace(),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 3,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BoldSubHeader(text: 'Community', context: context),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(
                              Icons.groups,
                              size: 64,
                              color: _event!.color,
                            ),
                            BoldSubHeader(
                              text: '${_communityService.numOfActiveUsers}',
                              context: context,
                              height: 1,
                            )
                          ],
                        ),
                        RewardBadge(
                          color: _event!.color,
                          size: 80,
                          value: _communityService.numOfOverallAchievedLocations,
                        ),
                      ],
                    ),
                    const SmallVSpace(),
                    Small(
                      text: _communityService.numOfActiveUsers == 0
                          ? 'Du bist der erste Teilnehmer an dem Weekend-Event!'
                          : 'An diesem Weekend-Event ${_communityService.numOfActiveUsers == 1 ? 'hat' : 'haben'} bereits ${_communityService.numOfActiveUsers} PrioBikler teilgenommen und${_communityService.numOfActiveUsers == 1 ? '' : ' zusammen'} ${_communityService.numOfOverallAchievedLocations} Abzeichen gesammelt!',
                      context: context,
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BoldContent(text: 'Deine Gesammelten Abzeichen', context: context),
                        RewardBadge(
                          color: _event!.color,
                          size: 64,
                          value: _communityService.numOfAchievedLocations,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
