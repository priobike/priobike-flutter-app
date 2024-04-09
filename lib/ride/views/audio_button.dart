import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
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
        width: isLandscapeMode ? 105 : 90,
        top: 135, // Below the finish button.
        // Button is on the right in portrait mode and on the left in landscape mode.
        right: isLandscapeMode ? null : 0,
        left: isLandscapeMode ? 0 : null,
        child: SafeArea(
          child: Tile(
            onPressed: () => settings.setSaveAudioInstructionsEnabled(!settings.saveAudioInstructionsEnabled),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(24),
              bottomLeft: const Radius.circular(24),
              topRight: isLandscapeMode ? const Radius.circular(24) : const Radius.circular(0),
              bottomRight: isLandscapeMode ? const Radius.circular(24) : const Radius.circular(0),
            ),
            padding: const EdgeInsets.all(4),
            fill: Colors.black.withOpacity(0.4),
            content: Padding(
              padding: isLandscapeMode
                  ? const EdgeInsets.only(left: 6, right: 6, top: 16, bottom: 16)
                  : const EdgeInsets.only(left: 16, right: 6, top: 16, bottom: 16),
              child: settings.saveAudioInstructionsEnabled
                  ? Column(
                      children: [
                        const Icon(
                          Icons.volume_up,
                          color: Colors.white,
                        ),
                        const SmallHSpace(),
                        BoldSmall(
                          text: "Ton ein",
                          context: context,
                          color: Colors.white,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Icon(
                          Icons.volume_off,
                          color: Colors.white,
                        ),
                        const SmallHSpace(),
                        BoldSmall(
                          text: "Ton aus",
                          context: context,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ));
  }
}
