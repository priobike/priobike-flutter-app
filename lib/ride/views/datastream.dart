import 'package:flutter/material.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/ride/messages/observations.dart';
import 'package:priobike/ride/services/datastream.dart';
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

  @override
  void didChangeDependencies() {
    datastream = Provider.of<Datastream>(context);
    settings = Provider.of<Settings>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (settings.datastreamMode == DatastreamMode.disabled) return Container();
    if (datastream.subscriptions.isEmpty) return Container();
    return Positioned(
      top: 8,
      right: 0,
      child: SafeArea(
        child: Tile(
          fill: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
          content: Row(children: [
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
          ]),
        ),
      ),
    );
  }
}
