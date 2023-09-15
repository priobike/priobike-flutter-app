import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/countdown_timer.dart';
import 'package:priobike/gamification/community/model/event.dart';
import 'package:priobike/gamification/community/model/location.dart';

class WaitingForEventView extends StatelessWidget {
  final CommunityEvent event;

  const WaitingForEventView({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BoldContent(
          text: 'nächstes Event am ${DateFormat('dd.MM').format(event.startTime)}',
          context: context,
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
        ),
        CountdownTimer(timestamp: event.startTime),
        Header(text: event.title, context: context),
      ],
    );
  }
}

class ActiveEventView extends StatelessWidget {
  final CommunityEvent event;

  final List<EventLocation> locations;

  const ActiveEventView({Key? key, required this.event, required this.locations}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(text: event.title, context: context),
        SubHeader(text: locations.length.toString(), context: context),
      ],
    );
  }
}
