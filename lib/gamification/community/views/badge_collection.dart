import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/community/service/community_service.dart';
import 'package:priobike/gamification/community/views/badge.dart';
import 'package:priobike/main.dart';

class BadgeCollection extends StatefulWidget {
  const BadgeCollection({Key? key}) : super(key: key);

  @override
  State<BadgeCollection> createState() => _BadgeCollectionState();
}

class _BadgeCollectionState extends State<BadgeCollection> {
  List<AchievedLocation> _achievedLocations = [];

  StreamSubscription? _stream;

  @override
  void initState() {
    _stream = getIt<CommunityService>().getStreamOfAllBadges().listen((results) {
      setState(() {
        _achievedLocations = results;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _stream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: SingleChildScrollView(
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
                      child: AppBackButton(onPressed: () => Navigator.pop(context)),
                    ),
                    const HSpace(),
                    SubHeader(text: 'Deine Abzeichen', context: context)
                  ],
                ),
                const SmallVSpace(),
                ..._achievedLocations
                    .map(
                      (loc) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            border: Border.all(
                              width: 1,
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                            ),
                            borderRadius: BorderRadius.circular(24),
                            color: Theme.of(context).colorScheme.surface),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Icon(
                              Icons.shield,
                              color: Color(loc.color),
                              size: 48,
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  BoldSubHeader(text: loc.title, context: context),
                                  Content(text: StringFormatter.getDateStr(loc.timestamp), context: context),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
