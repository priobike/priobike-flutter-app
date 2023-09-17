import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/views/feature_card.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/community/model/event.dart';
import 'package:priobike/gamification/community/service/community_service.dart';
import 'package:priobike/gamification/community/views/event_page.dart';
import 'package:priobike/gamification/community/views/event_view.dart';
import 'package:priobike/gamification/community/views/community_tutorial.dart';
import 'package:priobike/main.dart';

/// This card is displayed on the home view and holds all information about the users participation in the community events.

class CommunityCard extends StatefulWidget {
  const CommunityCard({Key? key}) : super(key: key);

  @override
  State<CommunityCard> createState() => _CommunityCardState();
}

class _CommunityCardState extends State<CommunityCard> {
  late CommunityService _communityService;

  CommunityEvent? get _event => _communityService.event;

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

  @override
  Widget build(BuildContext context) {
    return GamificationFeatureCard(
      featureKey: GamificationUserService.communityFeatureKey,
      // If the feature is enabled, show progress bars of the users challenges and the profile view.
      featurePage: _communityService.eventStarted ? const CommunityEventPage() : null,
      featureEnabledContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BoldContent(
            text: 'Wochenendradeln',
            context: context,
          ),
          if (_communityService.eventStarted) ActiveEventView(event: _event!, locations: _communityService.locations),
          if (_communityService.waitingForEvent) WaitingForEventView(event: _event!),
        ],
      ),
      // If the feature is disabled, show an info widget which directs the user to an intro page.
      tutorialPage: const CommunityTutorial(),
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
