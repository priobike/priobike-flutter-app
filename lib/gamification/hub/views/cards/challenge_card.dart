import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          ChallengeProgressBar(value: 1.7, target: 2.5),
          ChallengeProgressBar(value: 20, target: 170),
        ],
      ),
    );
  }
}

class ChallengeProgressBar extends StatelessWidget {
  final double value;

  final double target;

  const ChallengeProgressBar({
    Key? key,
    required this.value,
    required this.target,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var progress = (value / target * 100).toInt();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox.fromSize(
        size: const Size.fromHeight(32),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(32)),
              ),
              clipBehavior: Clip.hardEdge,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    flex: progress,
                    child: Container(
                      color: CI.blue,
                      child: (progress >= 50)
                          ? Center(
                              child: BoldSmall(
                                text: '$value / $target',
                                context: context,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Expanded(
                    flex: 100 - progress,
                    child: Container(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
                      child: (progress < 50)
                          ? Center(
                              child: BoldSmall(
                                text: '$value / $target',
                                context: context,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            FractionallySizedBox(
              widthFactor: value / target,
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
          ],
        ),
      ),
    );
  }
}
