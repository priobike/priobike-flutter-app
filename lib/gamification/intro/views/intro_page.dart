import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';

abstract class GameIntroPage extends AnimatedWidget {
  IconData get confirmButtonIcon;

  String get confirmButtonLabel;

  Widget get mainContent;

  void onBackButtonTab(BuildContext context);

  void onConfirmButtonTab(BuildContext context);

  const GameIntroPage({
    Key? key,
    required AnimationController controller,
  }) : super(key: key, listenable: controller);

  Animation<Offset> get _buttonAnimation => Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: listenable as Animation<double>,
        curve: Curves.easeIn,
      ));

  Animation<Offset> get _contentAnimation => Tween<Offset>(
        begin: const Offset(0.0, -1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: listenable as Animation<double>,
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
                child: mainContent,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AppBackButton(onPressed: () => onBackButtonTab(context)),
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
                    onPressed: () => onConfirmButtonTab(context),
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
