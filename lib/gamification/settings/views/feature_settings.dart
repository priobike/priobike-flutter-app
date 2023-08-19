import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/gamification/common/utils.dart';
import 'package:priobike/gamification/hub/views/custom_hub_page.dart';
import 'package:priobike/gamification/settings/services/settings_service.dart';
import 'package:priobike/main.dart';

class GameComponentsSettings extends StatefulWidget {
  const GameComponentsSettings({Key? key}) : super(key: key);

  @override
  State<GameComponentsSettings> createState() => _GameComponentsSettingsState();
}

class _GameComponentsSettingsState extends State<GameComponentsSettings> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: ShortDuration());
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
              Center(
                child: Content(text: 'Wähle die Features aus, die Du nutzen möchtest.', context: context),
              ),
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

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    _settingsService = getIt<GameSettingsService>();
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
    var selected = _settingsService.isFeatureEnabled(widget.featureKey);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Tile(
        showShadow: false,
        borderWidth: 3,
        borderColor: selected ? theme.colorScheme.primary : Colors.grey.withOpacity(0.25),
        splash: Colors.grey.withOpacity(0.1),
        fill: theme.colorScheme.background,
        onPressed: () => _settingsService.enableOrDisableFeature(widget.featureKey),
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
