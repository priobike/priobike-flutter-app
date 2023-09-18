import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/countdown_timer.dart';
import 'package:priobike/gamification/community/service/community_service.dart';
import 'package:priobike/main.dart';

class WaitingForEventView extends StatelessWidget {
  final CommunityService service;

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
        Header(text: '$value', context: context, height: 1),
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
            getInfoIcon(Icons.shield, getIt<CommunityService>().numOfAchievedLocations, CI.blue, context),
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
  final CommunityService service;

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
