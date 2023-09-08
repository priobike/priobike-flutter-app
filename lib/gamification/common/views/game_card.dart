import 'package:flutter/material.dart';

/// Wrapper class for the cards shown in the gamification hub view. Provides a uniformly styled card,
/// in which a custom content can be inserted.
class GamificationCard extends StatelessWidget {
  /// Content to be displayed inside of the element card.
  final Widget content;

  /// View to open when the card is tapped.
  final Widget? directionView;

  final Color? splashColor;

  const GamificationCard({
    Key? key,
    required this.content,
    this.directionView,
    this.splashColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          width: 1,
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.07),
        ),
      ),
      child: directionView == null
          ? Padding(padding: const EdgeInsets.all(16), child: content)
          : Material(
              borderRadius: BorderRadius.circular(24),
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                splashColor: splashColor ?? Theme.of(context).colorScheme.background,
                highlightColor: splashColor ?? Theme.of(context).colorScheme.background,
                onTap: () async {
                  await Future.delayed(const Duration(milliseconds: 250));
                  if (context.mounted) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => directionView!));
                  }
                },
                child: Padding(padding: const EdgeInsets.all(16), child: content),
              ),
            ),
    );
  }
}
