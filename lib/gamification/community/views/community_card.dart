import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/feature_card.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/community/service/community_service.dart';
import 'package:priobike/gamification/community/views/badge_collection.dart';
import 'package:priobike/gamification/community/views/event_page.dart';
import 'package:priobike/gamification/common/views/countdown_timer.dart';
import 'package:priobike/main.dart';

/// This card is displayed on the home view and holds all information about the users participation in the weekend events.
class EventCard extends StatefulWidget {
  const EventCard({Key? key}) : super(key: key);

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  /// Event service to gather all the relevant data about the current event.
  late EventService _communityService;

  @override
  void initState() {
    _communityService = getIt<EventService>();
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

  @override
  Widget build(BuildContext context) {
    return GamificationFeatureCard(
      featureKey: GamificationUserService.communityFeatureKey,
      // If the feature is enabled, show progress bars of the users challenges and the profile view.
      onEnabled: () {},
      featurePage: _communityService.activeEvent
          ? const CommunityEventPage()
          : (_communityService.waitingForEvent && _communityService.numOfAchievedBadges > 0
              ? const BadgeCollection()
              : null),
      featureEnabledContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// Display card content according to the current events status.
          if (_communityService.activeEvent) ActiveEventView(service: _communityService),
          if (_communityService.waitingForEvent) WaitingForEventView(service: _communityService),
          if (!_communityService.activeEvent && !_communityService.waitingForEvent)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.shield,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                    size: 80,
                  ),
                  const SmallVSpace(),
                  BoldSubHeader(
                    text: 'Gerade gibt es leider kein Wochenend-Event',
                    context: context,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
      featureDisabledContent: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: BoldSubHeader(
                text: 'PrioBike Wochenendradeln',
                context: context,
                textAlign: TextAlign.center,
              ),
            ),
            const SmallHSpace(),
            SizedBox(
              width: 96,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Container(
                      width: 0,
                      height: 0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CI.blue.withOpacity(0.05),
                            blurRadius: 24,
                            spreadRadius: 24,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.01),
                            blurRadius: 24,
                            spreadRadius: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Transform.rotate(
                      angle: 0,
                      child: const Icon(
                        Icons.groups,
                        size: 80,
                        color: CI.blue,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class WaitingForEventView extends StatelessWidget {
  final EventService service;

  const WaitingForEventView({Key? key, required this.service}) : super(key: key);

  Widget getInfoIcon(IconData icon, int value, Color color, var context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Icon(icon, size: 52, color: color),
        ),
        if (value > 0) Header(text: '$value', context: context, height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SmallVSpace(),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            getInfoIcon(Icons.shield, getIt<EventService>().numOfAchievedLocations, CI.blue, context),
          ],
        ),
        const SmallVSpace(),
        Text(
          'Nächstes Weekend-Event startet in:',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'HamburgSans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          ),
        ),
        CountdownTimer(
          timestamp: service.event!.startTime,
          style: Theme.of(context).textTheme.titleSmall!.merge(
                TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                  height: 1,
                ),
              ),
        ),
        const SmallVSpace(),
        if (service.numOfAchievedBadges > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              BoldSmall(
                  text: 'Abzeichensammlung',
                  context: context,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
              const Icon(Icons.redo)
            ],
          ),
      ],
    );
  }
}

class ActiveEventView extends StatelessWidget {
  final EventService service;

  const ActiveEventView({Key? key, required this.service}) : super(key: key);

  Widget getInfoIcon(IconData icon, int value, Color color, var context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 52, color: color),
        Header(text: '$value', context: context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SmallVSpace(),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            getInfoIcon(Icons.location_on, service.locations.length, Colors.grey, context),
            getInfoIcon(Icons.shield, service.numOfAchievedLocations, service.event!.color, context),
          ],
        ),
        const SmallVSpace(),
        Text(
          service.event!.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'HamburgSans',
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: service.event!.color,
          ),
        ),
        const SmallVSpace(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            BoldSmall(
                text: 'noch ', context: context, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
            CountdownTimer(
              timestamp: service.event!.endTime,
            ),
          ],
        ),
      ],
    );
  }
}
