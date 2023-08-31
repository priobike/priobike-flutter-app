import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/database/database.dart';

class NewChallengeDialog extends StatelessWidget {
  final Challenge challenge;

  const NewChallengeDialog({Key? key, required this.challenge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.25),
              spreadRadius: 0,
              blurRadius: 5,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SubHeader(
                text: challenge.isWeekly ? 'Neue Wochenchallenge:' : 'Neue Tageschallenge:',
                context: context,
                textAlign: TextAlign.center,
              ),
              const SmallVSpace(),
              
              const SmallVSpace(),
            ],
          ),
        ),
      ),
    );
  }
}

class ChallengeWidget extends StatelessWidget {
  final Challenge challenge;
  const ChallengeWidget({Key? key, required this.challenge, }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5)),
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox.fromSize(
                          size: const Size.square(48),
                          child: Stack(
                            children: [
                              Center(
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: CI.blue.withOpacity(0.25),
                                        spreadRadius: 12,
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Icon(
                                challenge.isWeekly ? Icons.emoji_events : Icons.military_tech,
                                size: 48,
                              ),
                            ],
                          ),
                        ),
                        const SmallHSpace(),
                        Expanded(
                          child: BoldSmall(
                            text: challenge.description,
                            context: context,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Small(text: '+${challenge.xp}XP', context: context),
                        const SmallHSpace(),
                      ],
                    ),
                  ],
                ),
              );
  }
}
