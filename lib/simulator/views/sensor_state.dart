import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/main.dart';
import 'package:priobike/ride/services/speedsensor.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/services/settings.dart';

class SensorState extends StatefulWidget {
  const SensorState({super.key});

  @override
  SensorStateState createState() => SensorStateState();
}

class SensorStateState extends State<SensorState> {
  /// The settings service, injected by [GetIt].
  late final Settings settings;

  /// The simulator service, injected by [GetIt].
  late final SpeedSensor speedSensor;

  void onSettingsUpdate() {
    setState(() {});
  }

  void onSpeedSensorUpdate() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    settings = getIt<Settings>();
    speedSensor = getIt<SpeedSensor>();

    settings.addListener(onSettingsUpdate);
    speedSensor.addListener(onSpeedSensorUpdate);
  }

  @override
  void dispose() {
    settings.removeListener(onSettingsUpdate);
    speedSensor.removeListener(onSpeedSensorUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (settings.positioningMode != PositioningMode.sensor) return Container();

    return Tile(
      fill: Theme.of(context).colorScheme.surfaceVariant,
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            speedSensor.adapterState == BluetoothAdapterState.on ? Icons.bluetooth : Icons.bluetooth_disabled,
            color: speedSensor.adapterState == BluetoothAdapterState.on ? CI.radkulturGreen : CI.radkulturYellow,
          ),
          const SizedBox(height: 2),
          Icon(
            speedSensor.isSetUp ? Icons.sensors : Icons.sensors_off,
            color: speedSensor.loading
                ? Theme.of(context).colorScheme.onTertiary
                : speedSensor.failure
                    ? CI.radkulturYellow
                    : CI.radkulturGreen,
          ),
        ],
      ),
    );
  }
}
