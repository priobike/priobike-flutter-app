import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/gamification/common/utils.dart';

/// Widget which displays a tutorial page for something regarding the gamification.
/// Each Page consist of a back button at the top, a list of content widgets and a confirmation button at the bottom.
class TutorialPage extends StatefulWidget {
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

  const TutorialPage({
    Key? key,
    this.confirmButtonIcon = Icons.check,
    required this.confirmButtonLabel,
    this.withContentFade = true,
    this.onBackButtonTab,
    required this.onConfirmButtonTab,
    required this.contentList,
  }) : super(key: key);

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  /// Animation for the confirmation button. The button slides in from the bottom.
  Animation<Offset> get _buttonAnimation => Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ));

  /// Animation for the list of content widgets, which slide in from the top.
  Animation<Offset> get _contentAnimation => Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ));

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: const MediumDuration());
    _animationController.forward().then((value) => _animationController.duration = const ShortDuration());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
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
                        stops: widget.withContentFade ? [0, 0.05, 0.85, 0.95] : null,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.contentList,
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
                    const SmallVSpace(),
                    Row(
                      children: [
                        AppBackButton(
                          onPressed: () async {
                            await _animationController.reverse();
                            if (widget.onBackButtonTab != null) {
                              widget.onBackButtonTab!();
                            } else {
                              if (mounted) Navigator.of(context).pop();
                            }
                          },
                        ),
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
                      icon: widget.confirmButtonIcon,
                      iconColor: Colors.white,
                      label: widget.confirmButtonLabel,
                      onPressed: widget.onConfirmButtonTab == null
                          ? null
                          : () async {
                              await _animationController.reverse();
                              widget.onConfirmButtonTab!();
                            },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
