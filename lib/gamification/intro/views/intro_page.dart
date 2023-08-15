import 'package:flutter/material.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';

/// Widget which displays a page of the gamification intro. Handles the animation to let the content appear and
/// ensures a uniform style between the intro pages.
///
/// Each Page consist of a back button at the top, a list of content widgets and a confirmation button at the bottom.
class GameIntroPage extends StatelessWidget {
  /// Controller which handles the appear animation.
  final AnimationController animationController;

  /// Icon which is displayed on the confirmation button.
  final IconData confirmButtonIcon;

  /// Text label on the confirmation button.
  final String confirmButtonLabel;

  /// Determines wether the content list should be faded at the top and bottom.
  final bool withContentFade;

  /// Callback for the back button at the top.
  final Function()? onBackButtonTab;

  /// Callback for the confirmation button.
  final Function()? onConfirmButtonTab;

  /// List of content widgets displayed on the page.
  final List<Widget> contentList;

  const GameIntroPage({
    Key? key,
    required this.animationController,
    this.confirmButtonIcon = Icons.check,
    required this.confirmButtonLabel,
    this.withContentFade = true,
    required this.onBackButtonTab,
    required this.onConfirmButtonTab,
    required this.contentList,
  }) : super(key: key);

  /// Animation for the confirmation button. The button slides in from the bottom.
  Animation<Offset> get _buttonAnimation => Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeIn,
      ));

  /// Animation for the list of content widgets, which slide in from the top.
  Animation<Offset> get _contentAnimation => Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeIn,
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SlideTransition(
                position: _contentAnimation,
                child: SafeArea(
                  child: HPad(
                    child: Fade(
                      stops: withContentFade ? [0, 0.05, 0.85, 0.95] : null,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: contentList,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AppBackButton(onPressed: onBackButtonTab),
                    ],
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: _buttonAnimation,
                child: Pad(
                  child: BigButton(
                      icon: confirmButtonIcon,
                      iconColor: Colors.white,
                      label: confirmButtonLabel,
                      onPressed: onConfirmButtonTab),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
