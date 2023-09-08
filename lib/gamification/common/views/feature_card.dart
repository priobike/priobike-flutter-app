import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';
import 'package:priobike/main.dart';

class DisabledFeatureCard extends StatelessWidget {
  /// Content to be displayed inside of the element card.
  final Widget content;

  final Widget introPage;

  const DisabledFeatureCard({
    Key? key,
    required this.content,
    required this.introPage,
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
      child: Material(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          splashColor: CI.blue,
          highlightColor: CI.blue,
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 250));
            if (context.mounted) {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => introPage));
            }
          },
          child: Padding(padding: const EdgeInsets.all(16), child: content),
        ),
      ),
    );
  }
}

class EnabledFeatureCard extends StatefulWidget {
  /// Content to be displayed inside of the element card.
  final Widget content;

  final Widget? directionView;

  final String? featureKey;

  const EnabledFeatureCard({
    Key? key,
    required this.content,
    this.directionView,
    this.featureKey,
  }) : super(key: key);
  @override
  State<EnabledFeatureCard> createState() => _EnabledFeatureCardState();
}

class _EnabledFeatureCardState extends State<EnabledFeatureCard> {
  bool showMenu = false;

  List<String> get enabledFeatures => getIt<GamificationUserService>().enabledFeatures;

  bool get showMoveUpButton => enabledFeatures.firstOrNull != widget.featureKey;

  bool get showMoveDownButton => enabledFeatures.lastOrNull != widget.featureKey;

  Widget getMenuItem({required IconData icon, Function()? onPressed}) {
    return AnimatedButton(
      scaleFactor: 0.8,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: AnimatedButton(
        scaleFactor: 0.95,
        onPressed: widget.directionView == null
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => widget.directionView!),
                ),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            GestureDetector(
              onTap: showMenu ? () => setState(() => showMenu = false) : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                foregroundDecoration:
                    showMenu ? BoxDecoration(color: Theme.of(context).colorScheme.background.withOpacity(0.75)) : null,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    width: 1,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.07),
                  ),
                ),
                child: widget.content,
              ),
            ),
            AnimatedOpacity(
              opacity: showMenu ? 1 : 0,
              duration: TinyDuration(),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      width: 0.5,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.fromSize(size: const Size.square(32 + 8)),
                      getMenuItem(icon: Icons.delete),
                      if (showMoveUpButton) getMenuItem(icon: Icons.keyboard_arrow_up),
                      if (showMoveDownButton) getMenuItem(icon: Icons.keyboard_arrow_down),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.featureKey != null)
              GestureDetector(
                onTap: () => setState(() => showMenu = !showMenu),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: AnimatedSwitcher(
                    duration: TinyDuration(),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: showMenu
                        ? const Icon(
                            Icons.close_rounded,
                            size: 32,
                            key: ValueKey("hide"),
                          )
                        : const Icon(
                            Icons.more_vert,
                            size: 32,
                            key: ValueKey("show"),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
