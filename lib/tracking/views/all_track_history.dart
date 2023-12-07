import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tracking/views/track_history_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllTracksHistoryView extends StatefulWidget {
  const AllTracksHistoryView({super.key});

  @override
  State<StatefulWidget> createState() => AllTracksHistoryViewState();
}

class AllTracksHistoryViewState extends State<AllTracksHistoryView> {
  /// The associated tracking service, which is injected by the provider.
  late Tracking tracking;

  /// The image of the route start icon.
  ui.Image? startImage;

  /// The image of the route destination icon.
  ui.Image? destinationImage;

  /// The used disk space.
  String? usedDiskSpace;

  /// The previous tracks.
  List<Track> previousTracks = List.empty(growable: true);

  /// Called when a listener callback of a ChangeNotifier is fired.
  Future<void> update() async {
    await loadTracks();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    tracking = getIt<Tracking>();
    tracking.addListener(update);

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        ByteData startBd = await rootBundle.load("assets/images/start.drawio.png");
        final Uint8List startBytes = Uint8List.view(startBd.buffer);
        final ui.Codec startCodec = await ui.instantiateImageCodec(startBytes);
        startImage = (await startCodec.getNextFrame()).image;

        ByteData destinationBd = await rootBundle.load("assets/images/destination.drawio.png");
        final Uint8List destinationBytes = Uint8List.view(destinationBd.buffer);
        final ui.Codec destinationCodec = await ui.instantiateImageCodec(destinationBytes);
        destinationImage = (await destinationCodec.getNextFrame()).image;

        await tracking.loadPreviousTracks();

        // Needs to be loaded after the tracks are loaded because we use them.
        await loadTracks();

        setState(() {});
      },
    );
  }

  /// Loads the tracks.
  Future<void> loadTracks() async {
    previousTracks.clear();
    if (tracking.previousTracks != null && tracking.previousTracks!.isNotEmpty) {
      final backend = getIt<Settings>().backend;
      for (var i = tracking.previousTracks!.length - 1; i >= 0; i--) {
        Track track = tracking.previousTracks![i];
        // To get Production and Release or Staging.
        if (track.backend.regionName == backend.regionName) {
          previousTracks.add(track);
        }
      }
    }
    await loadStorage();
  }

  /// Loads the used disk space of the tracks.
  Future<void> loadStorage() async {
    if (previousTracks.isEmpty) {
      usedDiskSpace = "0 Byte";
      return;
    }

    // Get the bytes of the tracks in the shared preferences.
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getStringList(Tracking.tracksKey);
    final sharedPreferencesString = json?.join("");
    var bytes = utf8.encode(sharedPreferencesString ?? "").length;

    // Add the bytes of the track files on the disk.
    for (final track in previousTracks) {
      final directory = await track.trackDirectory;
      if (await directory.exists()) {
        final files = await directory.list(recursive: true).toList();
        bytes += int.parse(
            files.fold<int>(0, (previousValue, element) => previousValue + element.statSync().size).toString());
      }
    }

    // Add the size of all saved background images.
    bytes += await MapboxTileImageCache.calculateTotalSize();

    // Format the bytes.
    if (bytes < 1000) {
      usedDiskSpace = "${bytes.toStringAsFixed(0)} Byte";
    } else if (bytes < 1000000) {
      usedDiskSpace = "${(bytes / 1000).toStringAsFixed(2)} KB";
    } else if (bytes < 1000000000) {
      usedDiskSpace = "${(bytes / 1000000).toStringAsFixed(2)} MB";
    } else {
      usedDiskSpace = "${(bytes / 1000000000).toStringAsFixed(2)} GB";
    }
  }

  @override
  void dispose() {
    tracking.removeListener(update);
    super.dispose();
  }

  /// Show a dialog that asks if the track really shoud be deleted.
  void showDeleteDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return DialogLayout(
          title: 'Alle Fahrten löschen',
          text: "Bitte bestätige, dass Du die gespeicherten Fahrten löschen möchtest.",
          icon: Icons.delete_rounded,
          iconColor: Theme.of(context).colorScheme.primary,
          actions: [
            BigButtonPrimary(
              iconColor: Colors.black,
              icon: Icons.delete_forever_rounded,
              fillColor: CI.radkulturYellow,
              textColor: Colors.black,
              label: "Löschen",
              onPressed: () {
                tracking.deleteAllTracks();
                update();
                Navigator.of(context).pop();
              },
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
            ),
            BigButtonTertiary(
              label: "Abbrechen",
              onPressed: () => Navigator.of(context).pop(),
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width, minHeight: 36),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double shortcutRightPad = 16;
    final shortcutWidth = ((MediaQuery.of(context).size.width - 36) / 2) - shortcutRightPad;

    return AnnotatedRegionWrapper(
      backgroundColor: Theme.of(context).colorScheme.background,
      brightness: Theme.of(context).brightness,
      child: Scaffold(
        body: Fade(
          child: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AppBackButton(onPressed: () => Navigator.pop(context)),
                      const HSpace(),
                      SubHeader(text: "Alle Fahrten", context: context),
                      const Spacer(),
                      if (previousTracks.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: shortcutRightPad),
                          child: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => showDeleteDialog(context),
                          ),
                        ),
                    ],
                  ),
                  const VSpace(),
                  if ((tracking.previousTracks != null && tracking.previousTracks!.isNotEmpty) &&
                      (startImage != null && destinationImage != null))
                    HPad(
                      child: Wrap(
                        spacing: 18,
                        runSpacing: 18,
                        children: previousTracks
                            .asMap()
                            .entries
                            .map(
                              (track) => BlendIn(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCubic,
                                delay: Duration(milliseconds: 200 * track.key),
                                child: TrackHistoryItemTileView(
                                  key: ValueKey(track.value.sessionId),
                                  track: track.value,
                                  width: shortcutWidth,
                                  startImage: startImage!,
                                  destinationImage: destinationImage!,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  const VSpace(),
                  if (usedDiskSpace != null)
                    HPad(
                      child: BlendIn(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                        delay: Duration(milliseconds: 200 * previousTracks.length),
                        child: Content(
                          text: "${usedDiskSpace!} Speicher auf Deinem Telefon belegt",
                          context: context,
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  const VSpace(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
