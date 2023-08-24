import 'package:flutter/material.dart';

/// Wrapper class for the cards shown in the gamification hub view. Provides a uniformly styled card,
/// in which a custom content can be inserted.
class GameHubCard extends StatelessWidget {
  /// Content to be displayed inside of the element card.
  final Widget content;

  /// Handler function for a simple click on the card.
  final Function()? onTap;

  const GameHubCard({Key? key, required this.content, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
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
      ),
    );
  }
}
