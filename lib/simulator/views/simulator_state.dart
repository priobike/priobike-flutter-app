import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:priobike/simulator/services/simulator.dart';

enum TileAlignment {
  left,
  right,
}

class SimulatorState extends StatefulWidget {
  final TileAlignment tileAlignment;

  final bool onlyShowErrors;

  const SimulatorState({super.key, required this.tileAlignment, required this.onlyShowErrors});

  @override
  SimulatorStateState createState() => SimulatorStateState();
}

class SimulatorStateState extends State<SimulatorState> {
  /// The settings service, injected by [GetIt].
  late final Settings settings;

  /// The simulator service, injected by [GetIt].
  late final Simulator simulator;

  void onSettingsUpdate() {
    setState(() {});
  }

  void onSimulatorUpdate() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    settings = getIt<Settings>();
    simulator = getIt<Simulator>();

    settings.addListener(onSettingsUpdate);
    simulator.addListener(onSimulatorUpdate);
  }

  @override
  void dispose() {
    settings.removeListener(onSettingsUpdate);
    simulator.removeListener(onSimulatorUpdate);
    super.dispose();
  }

  Widget _statusInfo(String text, bool state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          text,
        ),
        const SizedBox(width: 8),
        Icon(
          state ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.xmark_circle_fill,
          color: state ? CI.radkulturGreen : CI.radkulturYellow,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!settings.enableSimulatorMode) return Container();

    final everythingCorrectlySetup = simulator.paired &&
        !simulator.driving &&
        simulator.client != null &&
        simulator.client!.connectionStatus != null &&
        simulator.client!.connectionStatus!.state == MqttConnectionState.connected;

    return everythingCorrectlySetup && widget.onlyShowErrors
        ? Container()
        : Tile(
            fill: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: widget.tileAlignment == TileAlignment.right
                ? const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  )
                : const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
            content: Column(
              crossAxisAlignment:
                  widget.tileAlignment == TileAlignment.right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SubHeader(
                  text: 'Simulator',
                  context: context,
                ),
                everythingCorrectlySetup
                    ? _statusInfo('Bereit', true)
                    : Column(
                        crossAxisAlignment: widget.tileAlignment == TileAlignment.right
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          _statusInfo(
                              'Verbunden (MQTT)',
                              simulator.client != null &&
                                  simulator.client!.connectionStatus != null &&
                                  simulator.client!.connectionStatus!.state == MqttConnectionState.connected),
                          const SizedBox(height: 2),
                          _statusInfo('Verbunden (Sim.)', simulator.paired),
                          const SizedBox(height: 2),
                          _statusInfo('Bereit für Fahrt', !simulator.driving),
                        ],
                      ),
              ],
            ),
          );
  }
}
