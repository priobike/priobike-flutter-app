import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/main.dart';
import 'package:collection/collection.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/animated_button.dart';
import 'package:priobike/gamification/common/views/custom_dialog.dart';

/// A card to display the state of a given gamification feature on the home screen.
class GamificationFeatureCard extends StatefulWidget {
  /// The shared prefs key of the feature.
  final String featureKey;

  /// The content of the card, if the feature is enabled.
  final Widget featureEnabledContent;

  /// The page, the card navigates to, if the feature is enabled.
  final Widget? featurePage;

  /// The content of the card, if the feature is disabled.
  final Widget featureDisabledContent;

  /// The page, the card navigates to, if the feature is disabled.
  final Widget tutorialPage;

  const GamificationFeatureCard({
    Key? key,
    required this.featureKey,
    required this.featureEnabledContent,
    required this.featureDisabledContent,
    required this.tutorialPage,
    this.featurePage,
  }) : super(key: key);

  @override
  State<GamificationFeatureCard> createState() => _GamificationFeatureCardState();
}

class _GamificationFeatureCardState extends State<GamificationFeatureCard> {
  /// Profile service to check, whether the feature is enabeld and to listen to changes.
  late GamificationUserService _profileService;

  @override
  void initState() {
    _profileService = getIt<GamificationUserService>();
    _profileService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _profileService.removeListener(update);
    super.dispose();
  }

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  @override
  Widget build(BuildContext context) {
    bool featureEnabled = _profileService.enabledFeatures.contains(widget.featureKey);

    /// Show the fitting card design for whether the feature is enabled or disabled.
    if (featureEnabled) {
      return EnabledFeatureCard(
        featureKey: widget.featureKey,
        featurePage: widget.featurePage,
        content: widget.featureEnabledContent,
      );
    } else {
      return DisabledFeatureCard(
        content: widget.featureDisabledContent,
        tutorialPage: widget.tutorialPage,
      );
    }
  }
}

/// A card for displaying a disabled feature on the home screen.
class DisabledFeatureCard extends StatelessWidget {
  /// Content to be displayed inside of the feature card.
  final Widget content;

  /// Tutorial page to which the card directs to, if pressed.
  final Widget tutorialPage;

  const DisabledFeatureCard({
    Key? key,
    required this.content,
    required this.tutorialPage,
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
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => tutorialPage));
            }
          },
          child: Padding(padding: const EdgeInsets.all(16), child: content),
        ),
      ),
    );
  }
}

/// A card for displaying an enabled feature on the home screen.
class EnabledFeatureCard extends StatefulWidget {
  /// Content to be displayed inside of the card.
  final Widget content;

  /// Page to which the card directs the user to, if pressed.
  final Widget? featurePage;

  /// The key of the corresponding feature.
  final String featureKey;

  const EnabledFeatureCard({
    Key? key,
    required this.content,
    required this.featureKey,
    this.featurePage,
  }) : super(key: key);
  @override
  State<EnabledFeatureCard> createState() => _EnabledFeatureCardState();
}

class _EnabledFeatureCardState extends State<EnabledFeatureCard> {
  ///Whether to show the settings menu of the card, which enabled the user to move the card or disable the feature.
  bool showMenu = false;

  /// User service to apply changes to the feature settings.
  GamificationUserService get userService => getIt<GamificationUserService>();

  /// Whether the feature card can be moved up in the feature list.
  bool get showMoveUpButton => userService.enabledFeatures.firstOrNull != widget.featureKey;

  /// Whether the feature card can be moved down in the feature list.
  bool get showMoveDownButton => userService.enabledFeatures.lastOrNull != widget.featureKey;

  /// A custom button design for the disable feature dialog.
  Widget getDialogButton({
    required Color color,
    required IconData icon,
    required String label,
    required Function() onPressed,
  }) {
    return OnTabAnimation(
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

  /// A dialog which is opened, if the user presses the disable button in the menu, which asks the user to confirm.
  void showDisableFeatureDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return CustomDialog(
          content: Container(
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
                    getDialogButton(
                      label: 'Abbrechen',
                      icon: Icons.close_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                      color: CI.blue,
                    ),
                    getDialogButton(
                      label: 'Deaktivieren',
                      icon: Icons.not_interested,
                      onPressed: () {
                        userService.disableFeature(widget.featureKey);
                        Navigator.of(context).pop();
                      },
                      color: CI.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The design of a menu item, which invokes a given function when pressed.
  Widget getMenuItem({required IconData icon, Function()? onPressed}) {
    return OnTabAnimation(
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
      child: OnTabAnimation(
        scaleFactor: 0.95,
        onPressed: widget.featurePage == null
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => widget.featurePage!),
                ),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            GestureDetector(
              behavior: showMenu ? HitTestBehavior.opaque : null,
              onTap: showMenu ? () => setState(() => showMenu = false) : null,
              child: Container(
                padding: const EdgeInsets.all(16),
                foregroundDecoration: showMenu
                    ? BoxDecoration(
                        color: Theme.of(context).colorScheme.background.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(24),
                      )
                    : null,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    width: 1,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.07),
                  ),
                ),
                child: IgnorePointer(
                  ignoring: showMenu,
                  child: widget.content,
                ),
              ),
            ),
            // If the menu is opened, it is shown above the card at the positin of the menu button.
            AnimatedOpacity(
              opacity: showMenu ? 1 : 0,
              duration: ShortDuration(),
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
                          onPressed: () => userService.moveFeatureUp(widget.featureKey),
                        ),
                      if (showMoveDownButton)
                        getMenuItem(
                          icon: Icons.keyboard_arrow_down,
                          onPressed: () => userService.moveFeatureDown(widget.featureKey),
                        ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
            // Button to open or close the menu.
            GestureDetector(
              onTap: () => setState(() => showMenu = !showMenu),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: AnimatedSwitcher(
                  duration: ShortDuration(),
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
