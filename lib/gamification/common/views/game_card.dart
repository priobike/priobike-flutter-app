import 'package:flutter/material.dart';
import 'package:priobike/common/layout/tiles.dart';

/// Wrapper class for the cards shown in the gamification hub view. Provides a uniformly styled card,
/// in which a custom content can be inserted.
class GamificationCard extends StatelessWidget {
  /// Content to be displayed inside of the element card.
  final Widget content;

  /// Handler function for a simple click on the card.
  final Function()? onTap;

  const GamificationCard({Key? key, required this.content, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Tile(
        onPressed: onTap,
        splash: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
        fill: Theme.of(context).colorScheme.background,
        content: content,
      ),
    );
  }
}
