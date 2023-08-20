import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/game/colors.dart';
import 'package:priobike/game/models.dart';
import 'package:priobike/game/view.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/hub/views/cards/hub_card.dart';

class GameChallengesCard extends StatefulWidget {
  const GameChallengesCard({Key? key}) : super(key: key);

  @override
  State<GameChallengesCard> createState() => _GameChallengesCardState();
}

class _GameChallengesCardState extends State<GameChallengesCard> {
  @override
  Widget build(BuildContext context) {
    return GameHubCard(
      content: Column(
        children: const [
          ChallengeProgressBar(value: 1.7, target: 2.5),
          ChallengeProgressBar(value: 20, target: 170),
        ],
      ),
    );
  }
}

class ChallengeProgressBar extends StatefulWidget {
  final double value;

  final double target;

  const ChallengeProgressBar({
    Key? key,
    required this.value,
    required this.target,
  }) : super(key: key);
  @override
  State<ChallengeProgressBar> createState() => _ChallengeProgressBarState();
}

/// This bool determines wether the displayed level ring should be animated currently.
bool animateLevelRing = false;

class _ChallengeProgressBarState extends State<ChallengeProgressBar> {
  @override
  Widget build(BuildContext context) {
    var progress = (widget.value / widget.target * 100).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox.fromSize(
        size: const Size.fromHeight(64),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: SizedBox.fromSize(
                      size: const Size.fromHeight(42),
                      child: Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(left: 48),
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(32),
                                bottomRight: Radius.circular(32),
                              ),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Expanded(
                                  flex: progress,
                                  child: Container(
                                    color: CI.blue,
                                  ),
                                ),
                                Expanded(
                                  flex: 100 - progress,
                                  child: Container(
                                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 48),
                            child: FractionallySizedBox(
                              widthFactor: widget.value / widget.target,
                              heightFactor: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: CI.blue.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      iconRing,
                    ],
                  ),
                  Center(
                    child: BoldContent(
                      text: '${widget.value} / ${widget.target}',
                      context: context,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get iconRing => GestureDetector(
        onTap: () {
          if (animateLevelRing) return;
          setState(() => animateLevelRing = true);
          Future.delayed(LongTransitionDuration()).then((_) => setState(() => animateLevelRing = false));
        },
        child: AnimatedLevelRing(
          levels: levels,
          value: 0,
          color: Medals.silver.withOpacity(0.5),
          icon: Icons.emoji_events,
          ringSize: 60,
          buildWithAnimation: animateLevelRing,
        ),
      );

  List<Level> get levels => [
        Level(value: 0, title: '', color: CI.blue.withOpacity(0.5)),
        Level(value: 0, title: '', color: CI.blue.withOpacity(0.5)),
        Level(value: 0, title: '', color: CI.blue.withOpacity(0.5)),
        Level(value: 0, title: '', color: CI.blue.withOpacity(0.5)),
        Level(value: 0, title: '', color: CI.blue.withOpacity(0.5)),
        Level(value: 0, title: '', color: CI.blue.withOpacity(0.5)),
        Level(value: 0, title: '', color: CI.blue.withOpacity(0.5)),
      ];
}
