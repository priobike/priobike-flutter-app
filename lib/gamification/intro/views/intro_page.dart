import 'package:flutter/material.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';

abstract class GameIntroPage extends AnimatedWidget {
  IconData get confirmButtonIcon;

  String get confirmButtonLabel;

  bool get withContentFade;

  void onBackButtonTab(BuildContext context);

  void onConfirmButtonTab(BuildContext context);

  List<Widget> getContentElements(BuildContext context);

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
                child: IntroContent(
                  withFade: withContentFade,
                  elements: getContentElements(context),
                ),
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

class IntroContent extends StatelessWidget {
  final List<Widget> elements;

  final bool withFade;

  const IntroContent({
    Key? key,
    required this.elements,
    required this.withFade,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: HPad(
        child: Fade(
          stops: withFade ? [0, 0.05, 0.85, 0.95] : null,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: elements,
            ),
          ),
        ),
      ),
    );
  }
}
