import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/hub/views/custom_hub_page.dart';
import 'package:priobike/gamification/settings/services/settings_service.dart';
import 'package:priobike/main.dart';

/// This view enables the user to enable or disable the gamification features.
class GameFeaturesSettingsView extends StatefulWidget {
  const GameFeaturesSettingsView({Key? key}) : super(key: key);

  @override
  State<GameFeaturesSettingsView> createState() => _GameFeaturesSettingsViewState();
}

class _GameFeaturesSettingsViewState extends State<GameFeaturesSettingsView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  /// This text gives the user the necessary information about the feature selection process.
  final String infoText =
      'Wähle die Features aus, an denen Du teilnehmen möchtest. Nur die werden Dir dann auch angezeigt.';

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: ShortTransitionDuration());
    _animationController.forward();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GameHubPage(
      animationController: _animationController,
      title: 'Challenge-Features',
      content: CustomFadeTransition(
        controller: _animationController,
        child: HPad(
          child: Column(
            children: [
              const SmallVSpace(),
              HPad(
                child: Center(
                  child: BoldContent(text: infoText, context: context),
                ),
              ),
              const SmallVSpace(),
              ...GameSettingsService.gameFeaturesLabelMap.entries
                  .map((e) => GameFeatureElement(label: e.value, featureKey: e.key))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }
}

/// This widget displays a game feature which the user can enable or disable by tapping on it.
class GameFeatureElement extends StatefulWidget {
  final String label;

  final String featureKey;

  const GameFeatureElement({
    Key? key,
    required this.label,
    required this.featureKey,
  }) : super(key: key);

  @override
  State<GameFeatureElement> createState() => _GameFeatureElementState();
}

class _GameFeatureElementState extends State<GameFeatureElement> {
  /// The associated settings service, which is injected by the provider.
  late GameSettingsService _settingsService;

  bool _selected = false;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() => _selected = _settingsService.isFeatureEnabled(widget.featureKey))};

  @override
  void initState() {
    _settingsService = getIt<GameSettingsService>();
    _selected = _settingsService.isFeatureEnabled(widget.featureKey);
    _settingsService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _settingsService.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Tile(
        showShadow: false,
        borderWidth: 3,
        borderColor: _selected ? theme.colorScheme.primary : Colors.grey.withOpacity(0.25),
        splash: Colors.grey.withOpacity(0.1),
        fill: theme.colorScheme.background,
        onPressed: () {
          setState(() => _selected = !_selected);
          _settingsService.enableOrDisableFeature(widget.featureKey);
        },
        content: Center(
          child: SubHeader(
            text: widget.label,
            context: context,
          ),
        ),
      ),
    );
  }
}
