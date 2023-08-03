import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tracking/views/track_history_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllTracksHistoryView extends StatefulWidget {
  const AllTracksHistoryView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AllTracksHistoryViewState();
}

class AllTracksHistoryViewState extends State<AllTracksHistoryView> {
  /// The distance model.
  final vincenty = const Distance(roundResult: false);

  /// The left padding.
  double leftPad = 24;

  /// If the user has scrolled.
  bool hasScrolled = false;

  /// The scroll controller.
  late ScrollController scrollController;

  /// The associated tracking service, which is injected by the provider.
  late Tracking tracking;

  ui.Image? startImage;
  ui.Image? destinationImage;

  String? usedDiskSpace;

  /// Called when a listener callback of a ChangeNotifier is fired.
  Future<void> update() async {
    await loadStorage();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(
      () {
        if (scrollController.offset > 0) {
          hasScrolled = true;
        }
      },
    );
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

        // Need to be loaded after the tracks are loaded because we use them to calculate the total storage.
        loadStorage();
      },
    );
  }

  Future<void> loadStorage() async {
    if (tracking.previousTracks == null) return;

    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getStringList(Tracking.tracksKey);
    final sharedPreferencesString = json?.join("");
    var bytes = utf8.encode(sharedPreferencesString ?? "").length;

    for (final track in tracking.previousTracks!) {
      final directory = await track.trackDirectory;
      if (await directory.exists()) {
        final files = await directory.list(recursive: true).toList();
        bytes += int.parse(
            files.fold<int>(0, (previousValue, element) => previousValue + element.statSync().size).toString());
      }
    }

    if (bytes < 1000) {
      usedDiskSpace = "${bytes.toStringAsFixed(0)} Byte";
    } else if (bytes < 1000000) {
      usedDiskSpace = "${(bytes / 1000).toStringAsFixed(0)} KB";
    } else if (bytes < 1000000000) {
      usedDiskSpace = "${(bytes / 1000000).toStringAsFixed(0)} MB";
    } else {
      usedDiskSpace = "${(bytes / 1000000000).toStringAsFixed(0)} GB";
    }

    setState(() {});
  }

  @override
  void dispose() {
    scrollController.dispose();
    tracking.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double shortcutRightPad = 16;
    final shortcutWidth = (MediaQuery.of(context).size.width / 2) - shortcutRightPad;
    final shortcutHeight = max(shortcutWidth - (shortcutRightPad * 3), 128.0);

    final reversedTracks = tracking.previousTracks?.reversed.toList() ?? [];

    List<Widget> views = reversedTracks
        .map(
          (track) => TrackHistoryItemView(
            track: track,
            width: shortcutWidth,
            height: shortcutHeight,
            rightPad: 0,
            vincenty: vincenty,
            startImage: startImage,
            destinationImage: destinationImage,
          ),
        )
        .toList();

    List<Widget> animatedViews = views
        .asMap()
        .entries
        .map(
          (e) => BlendIn(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            delay: Duration(milliseconds: 200 * e.key),
            child: e.value,
          ),
        )
        .toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Fade(
          child: SingleChildScrollView(
            child: SafeArea(
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        AppBackButton(onPressed: () => Navigator.pop(context)),
                        const HSpace(),
                        SubHeader(text: "Alle Fahrten", context: context),
                      ],
                    ),
                    const VSpace(),
                    HPad(
                      child: ((tracking.previousTracks != null && tracking.previousTracks!.isNotEmpty) &&
                              (startImage != null && destinationImage != null))
                          ? GridView.count(
                              shrinkWrap: true,
                              crossAxisSpacing: 8,
                              padding: EdgeInsets.zero,
                              mainAxisSpacing: 8,
                              crossAxisCount: 2,
                              physics: const NeverScrollableScrollPhysics(),
                              children: animatedViews,
                            )
                          : Content(
                              text: "Kein Fahrten vorhanden.",
                              context: context,
                            ),
                    ),
                    const VSpace(),
                    if (usedDiskSpace != null)
                      Content(
                        text: "${usedDiskSpace!} Speicher belegt",
                        context: context,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                      ),
                    const VSpace(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
