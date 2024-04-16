import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:ui';

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
import 'package:priobike/common/lock.dart';
import 'package:priobike/common/map/image_cache.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tracking/views/track_history_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double shortcutRightPad = 16;

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

  /// The tracks that will be displayed.
  List<Widget> tracksToBeDisplayed = List.empty(growable: true);

  /// The number of tracks being displayed. (Pagination)
  int numberTracks = 12;

  /// The index of the track that needs to be animated. (Pagination)
  int animateTracksIndex = 0;

  /// The scroll controller of the single child scroll view.
  ScrollController scrollController = ScrollController();

  /// The lock to wait for animation of the track widgets.
  /// Lock time is 2 tracks * animation time.
  final Lock lock = Lock(milliseconds: 2 * 700);

  /// Called when a listener callback of a ChangeNotifier is fired.
  Future<void> update() async {
    await loadTracks();
    updateTrackWidgets();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    tracking = getIt<Tracking>();
    tracking.addListener(update);

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        ByteData startBd = await rootBundle.load("assets/images/start-noshadow.png");
        final Uint8List startBytes = Uint8List.view(startBd.buffer);
        final ui.Codec startCodec = await ui.instantiateImageCodec(startBytes);
        startImage = (await startCodec.getNextFrame()).image;

        ByteData destinationBd = await rootBundle.load("assets/images/destination-noshadow.png");
        final Uint8List destinationBytes = Uint8List.view(destinationBd.buffer);
        final ui.Codec destinationCodec = await ui.instantiateImageCodec(destinationBytes);
        destinationImage = (await destinationCodec.getNextFrame()).image;

        await tracking.loadPreviousTracks();

        // Needs to be loaded after the tracks are loaded because we use them.
        await loadTracks();

        // Add first 12 tracks.
        addTrackWidgets();

        setState(() {});

        // Add a scroll listener for pagination.
        scrollController.addListener(() {
          if (numberTracks < previousTracks.length) {
            // To only extend the list, when scroll position is close to the end of the list.
            // Calculation: 0.5 + (half the ratio of tracks displayed - padding to never be to close to 1).
            if (scrollController.offset >=
                scrollController.position.maxScrollExtent *
                    (0.5 + ((numberTracks / previousTracks.length) / 2) - 0.1)) {
              lock.run(() async {
                // Add new track history items.
                numberTracks = numberTracks + 12;
                animateTracksIndex = animateTracksIndex + 12;
                addTrackWidgets();
                await loadStorage();
                setState(() {});
              });
            }
          }
        });
      },
    );
  }

  /// Adds new track widgets.
  void addTrackWidgets() {
    for (int i = animateTracksIndex; i < numberTracks; i++) {
      if (previousTracks.length > i) {
        final track = previousTracks[i];
        final shortcutWidth = ((MediaQuery.of(context).size.width - 36) / 2) - shortcutRightPad;

        tracksToBeDisplayed.add(
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
              borderRadius: BorderRadius.circular(25),
            ),
            child: BlendIn(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              delay: Duration(milliseconds: 200 * (i - animateTracksIndex)),
              child: TrackHistoryItemTileView(
                key: ValueKey(track.sessionId),
                track: track,
                width: shortcutWidth,
                startImage: startImage!,
                destinationImage: destinationImage!,
              ),
            ),
          ),
        );
      }
    }
  }

  /// Updates all track widgets.
  void updateTrackWidgets() {
    if (tracksToBeDisplayed.isEmpty) return;
    tracksToBeDisplayed = [];
    for (int i = 0; i < numberTracks; i++) {
      if (previousTracks.length > i) {
        final track = previousTracks[i];
        final shortcutWidth = ((MediaQuery.of(context).size.width - 36) / 2) - shortcutRightPad;

        tracksToBeDisplayed.add(
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.05),
              borderRadius: BorderRadius.circular(25),
            ),
            child: BlendIn(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              child: TrackHistoryItemTileView(
                key: ValueKey(track.sessionId),
                track: track,
                width: shortcutWidth,
                startImage: startImage!,
                destinationImage: destinationImage!,
              ),
            ),
          ),
        );
      }
    }
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
      transitionBuilder: (context, animation, secondaryAnimation, child) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4 * animation.value, sigmaY: 4 * animation.value),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
      pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return DialogLayout(
          title: 'Alle Fahrten löschen',
          text: "Bitte bestätige, dass Du die gespeicherten Fahrten löschen möchtest.",
          actions: [
            BigButtonPrimary(
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
    return AnnotatedRegionWrapper(
      bottomBackgroundColor: Theme.of(context).colorScheme.background,
      colorMode: Theme.of(context).brightness,
      child: Scaffold(
        body: Fade(
          child: SingleChildScrollView(
            controller: scrollController,
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
                        children: tracksToBeDisplayed,
                      ),
                    ),
                  const VSpace(),
                  BlendIn(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 500),
                    child: HPad(
                      child: Content(
                        text:
                            "${numberTracks > previousTracks.length ? previousTracks.length : numberTracks} von ${previousTracks.length} Fahrten geladen",
                        context: context,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SmallVSpace(),
                  if (usedDiskSpace != null)
                    BlendIn(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 500),
                      child: HPad(
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
