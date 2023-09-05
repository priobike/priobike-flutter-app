import 'package:flutter/material.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/gamification/common/views/custom_route.dart';

/// Wrapper class for the cards shown in the gamification hub view. Provides a uniformly styled card,
/// in which a custom content can be inserted.
class GamificationCard extends StatelessWidget {
  /// Content to be displayed inside of the element card.
  final Widget content;

  /// View to open when the card is tapped.
  final Widget directionView;

  const GamificationCard({Key? key, required this.content, required this.directionView}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Tile(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => directionView)),
        splash: Colors.transparent,
        fill: Theme.of(context).colorScheme.background,
        content: content,
      ),
    );
  }
}
