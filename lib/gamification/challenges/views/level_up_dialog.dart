import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';

/// Dialog widget to pop up after one or multiple challenges were generated.
class LevelUpDialog extends StatefulWidget {
  const LevelUpDialog({
    Key? key,
  }) : super(key: key);
  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog> with SingleTickerProviderStateMixin {
  /// Animation controller to animate the dialog appearing.
  late final AnimationController _animationController;

  /// Animation to
  Animation<double> get animation => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastLinearToSlowEaseIn,
      ));

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: ShortDuration());
    _animationController.forward();
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var lightmode = Theme.of(context).brightness == Brightness.light;
    return ScaleTransition(
      scale: animation,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(lightmode ? 1 : 0.25),
                spreadRadius: 0,
                blurRadius: 50,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SmallHSpace(),
                    Expanded(
                      child: BoldContent(
                        text: 'Ich weiß ja nicht',
                        context: context,
                        textAlign: TextAlign.center,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                      ),
                    ),
                    const SmallHSpace(),
                  ],
                ),
                UpgradeWidget(
                  description: 'Wir müssen das halt alle irgendwann lernen, ganz erhlich, würd ich mal sagen',
                  onTap: () {},
                ),
                UpgradeWidget(
                  description: 'Upgrades sind nicht alles in diesem Lebel',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UpgradeWidget extends StatefulWidget {
  final Function onTap;
  final String description;
  const UpgradeWidget({
    Key? key,
    required this.description,
    required this.onTap,
  }) : super(key: key);

  @override
  State<UpgradeWidget> createState() => _UpgradeWidgetState();
}

class _UpgradeWidgetState extends State<UpgradeWidget> {
  bool tapDown = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.mediumImpact();
        setState(() => tapDown = true);
      },
      onTapUp: (_) {
        setState(() => tapDown = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => tapDown = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          border: Border.all(
            width: 0.5,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: tapDown ? CI.blue : Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
              blurRadius: tapDown ? 8 : 4,
            )
          ],
        ),
        child: Row(
          children: [Expanded(child: Content(text: widget.description, context: context))],
        ),
      ),
    );
  }
}
