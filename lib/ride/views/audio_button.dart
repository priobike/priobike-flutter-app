import 'package:flutter/material.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/logging/toast.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/settings/services/settings.dart';

class AudioButton extends StatefulWidget {
  const AudioButton({super.key});

  @override
  State<AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<AudioButton> {
  /// The associated settings service, which is injected by the provider.
  late Settings settings;

  /// The associated ride service, which is incjected by the provider.
  late Ride ride;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    settings = getIt<Settings>();
    settings.addListener(update);

    ride = getIt<Ride>();
    ride.addListener(update);
  }

  @override
  void dispose() {
    settings.removeListener(update);
    ride.removeListener(update);

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
            onPressed: () {
              if (ride.userSelectedSG == null) {
                settings.setAudioInstructionsEnabled(!settings.audioSpeedAdvisoryInstructionsEnabled);
              } else {
                getIt<Toast>().showError("Zentrieren, um Audio zu aktivieren");
              }
            },
            padding: const EdgeInsets.all(10),
            fill: Theme.of(context).colorScheme.surfaceVariant,
            content: settings.audioSpeedAdvisoryInstructionsEnabled
                ? Icon(
                    Icons.volume_up,
                    size: 32,
                    color: ride.userSelectedSG != null
                        ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                : Icon(
                    Icons.volume_off,
                    size: 32,
                    color: ride.userSelectedSG != null
                        ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
      ),
    );
  }
}
