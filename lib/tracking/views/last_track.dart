import 'package:flutter/material.dart' hide Route;
import 'package:flutter/scheduler.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/tracking/models/track.dart';
import 'package:priobike/tracking/services/tracking.dart';
import 'package:priobike/tracking/views/track_details.dart';

class LastTrackView extends StatefulWidget {
  const LastTrackView({Key? key}) : super(key: key);

  @override
  LastTrackViewState createState() => LastTrackViewState();
}

class LastTrackViewState extends State<LastTrackView> with SingleTickerProviderStateMixin {
  /// The distance model.
  final vincenty = const Distance(roundResult: false);

  /// The associated tracking service, which is injected by the provider.
  late Tracking tracking;

  Track? track;

  /// Called when a listener callback of a ChangeNotifier is fired.
  Future<void> update() async {
    if (tracking.previousTracks != null && tracking.previousTracks!.isNotEmpty) {
      print("sehrehjdrjdztj");
      track = tracking.previousTracks!.last;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    tracking = getIt<Tracking>();
    tracking.addListener(update);

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        await tracking.loadPreviousTracks();
        if (tracking.previousTracks != null && tracking.previousTracks!.isNotEmpty) {
          setState(() {
            track = tracking.previousTracks!.last;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    tracking.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (track == null) {
      return Container();
    }

    return Column(
      children: [
        SubHeader(
          text: 'Deine letzte Fahrt',
          context: context,
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
          textAlign: TextAlign.center,
        ),
        const SmallVSpace(),
        TrackDetailsView(track: track!),
      ],
    );
  }
}
