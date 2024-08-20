import 'package:flutter/material.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/services/settings.dart';

class AudioButton extends StatefulWidget {
  const AudioButton({super.key});

  @override
  State<AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<AudioButton> {
  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    settings = getIt<Settings>();
    settings.addListener(update);
  }

  @override
  void dispose() {
    settings.removeListener(update);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscapeMode = orientation == Orientation.landscape;

    return Positioned(
      top: 132, // Below the MapBox attribution.
      // Button is on the right in portrait mode and on the left in landscape mode.
      right: isLandscapeMode ? null : 12,
      left: isLandscapeMode ? 8 : null,
      child: SafeArea(
        child: SizedBox(
          width: 58,
          height: 58,
          child: Tile(
            onPressed: () => settings.setAudioInstructionsEnabled(!settings.audioSpeedAdvisoryInstructionsEnabled),
            padding: const EdgeInsets.all(10),
            fill: Theme.of(context).colorScheme.surfaceVariant,
            content: settings.audioSpeedAdvisoryInstructionsEnabled
                ? Icon(
                    Icons.volume_up,
                    size: 32,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                : Icon(
                    Icons.volume_off,
                    size: 32,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
      ),
    );
  }
}
