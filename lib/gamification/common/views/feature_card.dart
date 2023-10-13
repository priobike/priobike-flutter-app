import 'package:flutter/material.dart';
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/gamification/common/views/dialog_button.dart';
import 'package:priobike/main.dart';
import 'package:collection/collection.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/common/views/on_tap_animation.dart';
import 'package:priobike/gamification/common/views/custom_dialog.dart';

/// A card to display the state of a given gamification feature on the home screen.
class GamificationFeatureCard extends StatefulWidget {
  /// The shared prefs key of the feature.
  final String featureKey;

  /// The content of the card, if the feature is enabled.
  final Widget featureEnabledContent;

  /// Function that is called, when the feature is enabled by the user.
  final Function() onEnabled;

  /// The page, the card navigates to, if the feature is enabled.
  final Widget? featurePage;

  /// The content of the card, if the feature is disabled.
  final Widget featureDisabledContent;

  const GamificationFeatureCard({
    Key? key,
    required this.featureKey,
    required this.featureEnabledContent,
    required this.featureDisabledContent,
    this.featurePage,
    required this.onEnabled,
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
        onEnabled: widget.onEnabled,
        content: widget.featureDisabledContent,
        featureKey: widget.featureKey,
      );
    }
  }
}

/// A card for displaying a disabled feature on the home screen.
class DisabledFeatureCard extends StatelessWidget {
  /// Content to be displayed inside of the feature card.
  final Widget content;

  /// The key of the corresponding feature.
  final String featureKey;

  /// Function that is called, when the feature is enabled by the user.
  final Function() onEnabled;

  const DisabledFeatureCard({
    Key? key,
    required this.content,
    required this.featureKey,
    required this.onEnabled,
  }) : super(key: key);

  /// A dialog which is opened, if the user presses the card to enable a feature.
  void _enableFeatureDialog(var context) {
    showDialog(
      barrierColor: Colors.black.withOpacity(0.8),
      context: context,
      builder: (context) {
        return CustomDialog(
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                BoldSubHeader(
                  text: 'Möchtest Du dieses Feature aktivieren?',
                  context: context,
                  textAlign: TextAlign.center,
                ),
                const VSpace(),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomDialogButton(
                      label: 'Abbrechen',
                      onPressed: () => Navigator.of(context).pop(),
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
                    ),
                    const SmallHSpace(),
                    CustomDialogButton(
                      label: 'Aktivieren',
                      onPressed: () {
                        onEnabled();
                        getIt<GamificationUserService>().enableFeature(featureKey);
                        Navigator.of(context).pop();
                      },
                      color: CI.blue,
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

  @override
  Widget build(BuildContext context) {
    return OnTapAnimation(
      onPressed: () => _enableFeatureDialog(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            width: 1,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.07),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
            ),
          ],
        ),
        child: content,
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
  bool _showMenu = false;

  /// User service to apply changes to the feature settings.
  GamificationUserService get _userService => getIt<GamificationUserService>();

  /// Whether the feature card can be moved up in the feature list.
  bool get _showMoveUpButton => _userService.enabledFeatures.firstOrNull != widget.featureKey;

  /// Whether the feature card can be moved down in the feature list.
  bool get _showMoveDownButton => _userService.enabledFeatures.lastOrNull != widget.featureKey;

  /// A dialog which is opened, if the user presses the disable button in the menu, which asks the user to confirm.
  void _showDisableFeatureDialog() {
    showDialog(
      barrierColor: Colors.black.withOpacity(0.8),
      context: context,
      builder: (context) {
        return CustomDialog(
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                BoldSubHeader(
                  text: 'Möchtest Du dieses Feature wirklich deaktivieren?',
                  context: context,
                  textAlign: TextAlign.center,
                ),
                const VSpace(),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomDialogButton(
                      label: 'Abbrechen',
                      onPressed: () => Navigator.of(context).pop(),
                      color: CI.blue,
                    ),
                    const SmallHSpace(),
                    CustomDialogButton(
                      label: 'Deaktivieren',
                      onPressed: () {
                        _userService.disableFeature(widget.featureKey);
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
  Widget _getMenuItem({required IconData icon, Function()? onPressed}) {
    return OnTapAnimation(
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
      child: OnTapAnimation(
        scaleFactor: 0.95,
        onPressed: widget.featurePage == null
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => widget.featurePage!),
                ),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Tile(
              padding: const EdgeInsets.all(16),
              fill: Theme.of(context).colorScheme.background,
              content: IgnorePointer(
                ignoring: _showMenu,
                child: widget.content,
              ),
            ),
            if (_showMenu)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _showMenu = false),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            // If the menu is opened, it is shown above the card at the positin of the menu button.
            if (_showMenu)
              BlendIn(
                duration: const ShortDuration(),
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
                        _getMenuItem(
                          icon: Icons.not_interested,
                          onPressed: _showDisableFeatureDialog,
                        ),
                        if (_showMoveUpButton)
                          _getMenuItem(
                            icon: Icons.keyboard_arrow_up,
                            onPressed: () => _userService.moveFeatureUp(widget.featureKey),
                          ),
                        if (_showMoveDownButton)
                          _getMenuItem(
                            icon: Icons.keyboard_arrow_down,
                            onPressed: () => _userService.moveFeatureDown(widget.featureKey),
                          ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
            // Button to open or close the menu.
            GestureDetector(
              onTap: () => setState(() => _showMenu = !_showMenu),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: AnimatedSwitcher(
                  duration: const ShortDuration(),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: _showMenu
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
