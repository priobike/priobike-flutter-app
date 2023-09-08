import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
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

  GamificationUserService get userService => getIt<GamificationUserService>();

  bool get showMoveUpButton => userService.enabledFeatures.firstOrNull != widget.featureKey;

  bool get showMoveDownButton => userService.enabledFeatures.lastOrNull != widget.featureKey;

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

  Widget getCustomButton({
    required Color color,
    required IconData icon,
    required String label,
    required Function() onPressed,
  }) {
    return AnimatedButton(
      onPressed: onPressed,
      child: Tile(
        fill: color,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        borderRadius: BorderRadius.circular(24),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: Colors.white,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: BoldContent(
                text: label,
                context: context,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showDisableFeatureDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: const BorderRadius.all(Radius.circular(24)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BoldSubHeader(
                      text: 'Möchtest du dieses Feature wirklich deaktivieren?',
                      context: context,
                      textAlign: TextAlign.center,
                    ),
                    const VSpace(),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        getCustomButton(
                          label: 'Abbrechen',
                          icon: Icons.close_rounded,
                          onPressed: () => Navigator.of(context).pop(),
                          color: CI.blue,
                        ),
                        getCustomButton(
                          label: 'Deaktivieren',
                          icon: Icons.not_interested,
                          onPressed: () {
                            userService.enableOrDisableFeature(widget.featureKey!);
                            Navigator.of(context).pop();
                          },
                          color: CI.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
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
                      getMenuItem(
                        icon: Icons.not_interested,
                        onPressed: showDisableFeatureDialog,
                      ),
                      if (showMoveUpButton)
                        getMenuItem(
                          icon: Icons.keyboard_arrow_up,
                          onPressed: () => userService.moveFeatureUp(widget.featureKey!),
                        ),
                      if (showMoveDownButton)
                        getMenuItem(
                          icon: Icons.keyboard_arrow_down,
                          onPressed: () => userService.moveFeatureDown(widget.featureKey!),
                        ),
                      const SizedBox(height: 4),
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
