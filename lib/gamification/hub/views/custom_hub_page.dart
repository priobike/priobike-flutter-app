import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';

/// This view can be used for pages that are accessed from the game hub. It gives them a matching layout, containing
/// a back button and a header with a title and possibly a feature button.
class GameHubPage extends StatelessWidget {
  /// Animation controller to animate the page header with a fade transition.
  final AnimationController animationController;

  /// Title of the page, displayed in the header.
  final String title;

  /// Content of the page, displayed below the header in a scrollable view.
  final Widget content;

  /// This function is called when the back button is pressed.
  final Function()? backButtonCallback;

  /// The icon for the feature button. If this var is null, there will be no feature button
  final IconData? featureButtonIcon;

  /// This function is called when the feature button is pressed. If this var is null, there will be no feature button.
  final Function()? featureButtonCallback;

  const GameHubPage({
    Key? key,
    required this.animationController,
    required this.title,
    this.backButtonCallback,
    this.featureButtonIcon,
    this.featureButtonCallback,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Stack(
            children: [
              // Scroll view with header and content.
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SmallVSpace(),
                    // Header and feature button.
                    CustomFadeTransition(
                      controller: animationController,
                      interval: const Interval(0, 0.4, curve: Curves.easeIn),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const SizedBox(width: 72, height: 64),
                          Expanded(
                            child: SubHeader(
                              text: title,
                              context: context,
                              textAlign: TextAlign.center,
                            ),
                          ),

                          /// Small optional feature button with custom icon.
                          (featureButtonIcon == null || featureButtonCallback == null)
                              ? const SizedBox(width: 64, height: 0)
                              : Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: SmallIconButton(
                                    icon: featureButtonIcon!,
                                    onPressed: featureButtonCallback!,
                                    fill: Theme.of(context).colorScheme.background,
                                    splash: Theme.of(context).colorScheme.surface,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SmallVSpace(),
                    content
                  ],
                ),
              ),
              // Back button on top of the displayed statistics.
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    AppBackButton(
                        onPressed: backButtonCallback ??
                            (() {
                              animationController.duration = ShortAnimationDuration();
                              animationController.reverse().then((value) => Navigator.pop(context));
                            })),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}