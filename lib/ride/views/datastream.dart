import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/ride/messages/observations.dart';
import 'package:priobike/ride/services/datastream.dart';
import 'package:priobike/settings/models/datastream.dart';
import 'package:priobike/settings/services/settings.dart';

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

  /// The timer used to refresh the view.
  Timer? timer;

  /// The displayed time diff.
  String? timeDiff;

  /// The singleton instance of our dependency injection service.
  final getIt = GetIt.instance;

  /// Called when a listener callback of a ChangeNotifier is fired.
  late VoidCallback update;

  @override
  void initState() {
    super.initState();
    update = () => setState(() {});
    datastream = getIt<Datastream>();
    settings = getIt<Settings>();
    datastream.addListener(update);
    settings.addListener(update);
    timer = Timer.periodic(const Duration(seconds: 1), (_) => refreshTimeDiff());
  }

  @override
  void dispose() {
    datastream.removeListener(update);
    settings.removeListener(update);
    timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    refreshTimeDiff();
    super.didChangeDependencies();
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
            if ((datastream.detectorCar != null && datastream.detectorCar!.pct > 0) ||
                (datastream.detectorCyclists != null && datastream.detectorCyclists!.pct > 0))
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
