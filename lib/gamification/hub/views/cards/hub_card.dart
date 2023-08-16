import 'package:flutter/material.dart';

/// Wrapper class for the cards shown in the gamification hub view. Provides a uniformly styled card,
/// in which a custom content can be inserted.
class GameHubCard extends StatelessWidget {
  /// Content to be displayed inside of the element card.
  final Widget content;

  const GameHubCard({Key? key, required this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: content,
        ),
      ),
    );
  }
}
