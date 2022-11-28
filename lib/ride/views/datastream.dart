import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/ride/messages/observations.dart';
import 'package:priobike/ride/services/datastream.dart';
import 'package:priobike/ride/services/ride/ride.dart';
import 'package:priobike/settings/models/datastream.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class DatastreamView extends StatefulWidget {
  const DatastreamView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DatastreamViewState();
}

class DatastreamViewState extends State<DatastreamView> {
  /// The datastream service which is injected by the provider.
  late Datastream datastream;

  /// The settings service which is injected by the provider.
  late Settings settings;

  /// The ride service which is injected by the provider.
  late Ride ride;

  /// The timer used to refresh the view.
  Timer? timer;

  /// The displayed time diff.
  String? timeDiff;

  @override
  void didChangeDependencies() {
    datastream = Provider.of<Datastream>(context);
    settings = Provider.of<Settings>(context);
    ride = Provider.of<Ride>(context);
    refreshTimeDiff();
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => refreshTimeDiff());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  /// Refresh the time diff.
  void refreshTimeDiff() {
    if (datastream.primarySignal?.phenomenonTime == null) {
      setState(() => timeDiff = null);
      return;
    }
    final now = DateTime.now();
    final diff = now.difference(datastream.primarySignal!.phenomenonTime);
    setState(
      () {
        timeDiff = diff.inSeconds.toString();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (settings.datastreamMode == DatastreamMode.disabled) return Container();
    if (datastream.subscriptions.isEmpty) return Container();

    const comparisonLength = 40; // We want to compare the last 40 seconds of the vector.
    final predictionHistory = ride.calcHistory?.sublist(
          max(0, ride.calcHistory!.length - comparisonLength),
          ride.calcHistory!.length,
        ) ??
        [];
    final predictionVectorSquares = predictionHistory
        .map(
          (value) => Container(
            margin: const EdgeInsets.only(right: 1),
            height: 6,
            width: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              color:
                  (ride.currentRecommendation?.predictionGreentimeThreshold ?? 0) > value ? Colors.red : Colors.green,
            ),
          ),
        )
        .toList();
    final datastreamHistory = datastream.primarySignalHistory.sublist(
      max(0, datastream.primarySignalHistory.length - comparisonLength),
      datastream.primarySignalHistory.length,
    );
    final datastreamHistorySquares = datastreamHistory
        .map<Widget>(
          (value) => Container(
            margin: const EdgeInsets.only(right: 1),
            height: 6,
            width: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              color: value?.state.color ?? Colors.grey,
            ),
          ),
        )
        .toList();

    return Positioned(
      top: 48, // Below the MapBox attribution.
      right: 0,
      child: SafeArea(
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Tile(
                fill: Theme.of(context).colorScheme.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
                content: Row(
                  children: [
                    SizedBox(
                      width: comparisonLength * 3.0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Small(text: "Prognose vs. Realität", context: context),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: predictionVectorSquares,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: datastreamHistorySquares,
                          ),
                        ],
                      ),
                    ),
                    const SmallHSpace(),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
                          width: 1,
                        ),
                        color: datastream.primarySignal?.state.color ?? Colors.grey,
                      ),
                    ),
                    const SmallHSpace(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: datastream.primarySignal != null
                          ? [
                              Small(text: "Seit", context: context),
                              BoldSmall(text: "${timeDiff?.toString()}s", context: context),
                            ]
                          : [
                              Small(text: "Keine", context: context),
                              BoldSmall(text: "Daten", context: context),
                            ],
                    ),
                  ],
                ),
              ),
            ),
            if (datastream.detectorCar != null || datastream.detectorCyclists != null)
              Tile(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                fill: Theme.of(context).colorScheme.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
                content: BoldSmall(text: "Angefordert!", context: context),
              )
          ],
        ),
      ),
    );
  }
}
