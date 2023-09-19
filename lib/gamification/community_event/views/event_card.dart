import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/colors.dart';
import 'package:priobike/gamification/common/views/feature_card.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/community_event/service/event_service.dart';
import 'package:priobike/gamification/community_event/views/badge.dart';
import 'package:priobike/gamification/community_event/views/badge_collection.dart';
import 'package:priobike/gamification/community_event/views/event_page.dart';
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
  late EventService _eventService;

  @override
  void initState() {
    _eventService = getIt<EventService>();
    _eventService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _eventService.removeListener(update);
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
      featurePage: _eventService.activeEvent
          ? const CommunityEventPage()
          : (_eventService.waitingForEvent && _eventService.userBadges.isNotEmpty
              ? BadgeCollection(badges: _eventService.userBadges)
              : null),
      featureEnabledContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SmallHSpace(),
              BoldSubHeader(
                text: 'Stadtteil-Hopping',
                context: context,
                textAlign: TextAlign.start,
              ),
            ],
          ),

          /// Display card content according to the current events status.
          if (_eventService.activeEvent) ActiveEventView(service: _eventService),
          if (_eventService.waitingForEvent) WaitingForEventView(service: _eventService),
          if (!_eventService.activeEvent && !_eventService.waitingForEvent) NoEventView(service: _eventService),
        ],
      ),
      featureDisabledContent: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: BoldSubHeader(
                text: 'Stadtteil\nHopping',
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
                    alignment: Alignment.topLeft,
                    child: Transform.rotate(
                      angle: 0,
                      child: const Icon(
                        Icons.shield,
                        size: 56,
                        color: LevelColors.silver,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Transform.rotate(
                      angle: 0,
                      child: const Icon(
                        Icons.location_city,
                        size: 72,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SmallVSpace(),
        const RewardBadge(
          color: CI.blue,
          size: 64,
          icon: Icons.question_mark,
          achieved: true,
        ),
        const SmallVSpace(),
        Text(
          'Das nächste Event startet in:',
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
        if (service.userBadges.isNotEmpty)
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RewardBadge(
                color: CI.blue,
                size: 64,
                icon: service.event!.icon,
                achieved: service.wasCurrentEventAchieved,
              ),
            ),
          ],
        ),
        Text(
          service.event!.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'HamburgSans',
            fontSize: 30,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        const SmallVSpace(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            BoldSmall(
                text: 'endet in ',
                context: context,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
            CountdownTimer(
              timestamp: service.event!.endTime,
            ),
          ],
        ),
      ],
    );
  }
}

class NoEventView extends StatelessWidget {
  final EventService service;

  const NoEventView({Key? key, required this.service}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SmallVSpace(),
        Icon(
          Icons.shield,
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
          size: 80,
        ),
        const SmallVSpace(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: BoldContent(
            text: 'Das nächste Event findet bald statt!',
            context: context,
            textAlign: TextAlign.center,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
          ),
        ),
        const SmallVSpace(),
        if (service.userBadges.isNotEmpty)
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
