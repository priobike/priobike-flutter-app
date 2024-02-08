import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/positioning/sources/interface.dart';
import 'package:priobike/positioning/sources/sensor.dart';

/*
  the name of the speed sensor was acquired by doing a normal scan for bluetooth devices
  Important: Location has to be enabled, since the used speed sensor is a
  BLE device, which are only accessible if we can scan for devices nearby
  */
const String _speedSensorName = "SPD-BLE0594113";

/*
  To get the correct data from the sensor, we subscribed to all available
  services. Some of them had multiple characteristics.
  Some of the characteristics only had constant data. Others were also subscribable
  with updating data.
  We subscribed to every one of them & looked at the data they delivered, when
  we imitated the physical movement of a wheel with the sensor.

  Below you can find the service uuid along with it's characteristic uuid
  responsible for delivering new rotation data.

  By looking at the data, i guessed it's structured like this:
  [a, b, c, d, e, f, g]
  a= [constantly 1]
  b= current number of rotations
  c= increased by one, if b would have been higher than 255
  -> c++, if new_b % 255 < previous_b % 255
  f= current angle
  g= difference between current f and previously sent f
  d= [constantly 0]
  e= [constantly 0]
  */
const String serviceUuid = "00001816-0000-1000-8000-00805F9B34FB";
const String _characteristicsUuid = "00002A5B-0000-1000-8000-00805F9B34FB";

const double wheelSizeInch = 28;
const wheelCircumferenceMeter = math.pi * wheelSizeInch / 39.37;

class SpeedSensor with ChangeNotifier {
  /// Logger for this class.
  final log = Logger("Speed Sensor Service");

  /// The BluetoothDevice
  BluetoothDevice? device;

  /// The bool that holds the state if the sensor is set up.
  bool isSetUp = false;

  /// The bool that holds the state of any loading process.
  bool loading = false;

  /// The bool that holds the state of any failure.
  bool failure = false;

  /// The scan listener.
  StreamSubscription? _scanListener;

  /// The connection state listener.
  StreamSubscription? _adapterStateListener;

  /// The speed characteristic listener.
  StreamSubscription? _speedCharacteristicListener;

  /// The connection state.
  BluetoothAdapterState adapterState = BluetoothAdapterState.unknown;

  /// The speed characteristic.
  BluetoothCharacteristic? speedCharacteristic;

  /// Probably getting remove...
  int? _lastNumberOfRotations;

  /// The current status text.
  String statusText = "";

  /// tries connecting to speed sensor, if not already connected
  /// initializes _device, if not already initialized
  Future<void> initConnectionToSpeedSensor() async {
    // Start scanning devices if not connected yet.
    loading = true;
    failure = false;
    statusText = "Sensor wird gesucht.";
    notifyListeners();

    // get all bluetooth devices already connected to the system. (doesn't  seem to work)

    List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;

    // search for speed sensor in connected devices
    for (BluetoothDevice bluetoothDevice in connectedDevices) {
      if (bluetoothDevice.platformName == _speedSensorName) device = bluetoothDevice;
    }

    // Check device connected.
    if (!(device == null)) {
      log.i("device already connected, yay");
      statusText = "Sensor gefunden.";
      notifyListeners();
      connectSpeedSensor();
      return;
    } else {
      log.i("device not connected yet.");
    }
    log.i("initalizing connected devices");

    // speed sensor was not in connected devices, so we do a new bluetooth scan
    _scanListener = FlutterBluePlus.scanResults.listen((results) {
      /// the contents here are getting called everytime a new device was found in the scan
      log.i(results);
      // search speed sensor in list of all currently found devices
      ScanResult? sensorFound;
      for (ScanResult scanResult in results) {
        if (scanResult.advertisementData.localName == _speedSensorName) sensorFound = scanResult;
      }
      // No sensor found yet.
      if (sensorFound == null) return;
      device = sensorFound.device;
      log.i("found speed sensor!");
      statusText = "Sensor gefunden.";
      FlutterBluePlus.stopScan();
      loading = false;
      notifyListeners();

      // Next step. Connect to sensor.
      connectSpeedSensor();
    });

    // start bluetooth scan
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    // Wait 10 seconds because startScan can't be await.
    await Future.delayed(const Duration(seconds: 10));

    // Stop listening after scan unsuccessful.
    if (device == null) {
      _scanListener?.cancel();
      _scanListener = null;
      loading = false;
      statusText = "Sensor wurde nicht gefunden.";
      failure = true;
      notifyListeners();
    }
  }

  void stopScanningDevices() {
    FlutterBluePlus.stopScan();
    _scanListener?.cancel();
    _scanListener = null;
    loading = false;
    notifyListeners();
  }

  /// tries connecting to the speed sensor
  /// Note: _device has to be initialized
  Future<void> connectSpeedSensor() async {
    if (device == null) return;
    loading = true;
    statusText = "Verbinde Sensor";
    notifyListeners();

    await device!.connect();

    loading = false;
    notifyListeners();

    if (device!.isConnected) {
      statusText = "Sensor verbunden";
      notifyListeners();
      discoverServicesOfDevice();
    } else {
      statusText = "Sensor konnte nicht verbunden werden";
      failure = true;
      notifyListeners();
    }
  }

  /// tries connecting to the speed sensor
  /// Note: _device has to be initialized
  Future<void> disconnectSpeedSensor() async {
    if (device == null) return;
    await device!.disconnect();
  }

  void startBluetoothStateListener() {
    _adapterStateListener = FlutterBluePlus.adapterState.listen((state) {
      adapterState = state;
      if (adapterState == BluetoothAdapterState.off) {
        isSetUp = false;
        failure = true;
      }
      notifyListeners();
    });
  }

  void stopBluetoothStateListener() {
    _adapterStateListener?.cancel();
  }

  /// discovers all services of connected device
  /// Note: _device has to be initialized
  Future<void> discoverServicesOfDevice() async {
    if (device == null) return;
    if (!device!.isConnected) return;

    loading = true;
    statusText = "Suche nach Speed Service";
    notifyListeners();

    List<BluetoothService> services = await device!.discoverServices();

    statusText = "Services werden geprüft";
    notifyListeners();

    log.i("got services successfully");
    log.i(services);
    notifyListeners();

    // Search speed characteristic.
    for (BluetoothService bluetoothService in services) {
      for (BluetoothCharacteristic bluetoothCharacteristic in bluetoothService.characteristics) {
        if (bluetoothCharacteristic.uuid.toString().toUpperCase() == _characteristicsUuid) {
          speedCharacteristic = bluetoothCharacteristic;
          notifyListeners();
        }
      }
    }

    loading = false;
    statusText = speedCharacteristic != null ? "Service gefunden" : "Service nicht gefunden";
    notifyListeners();

    if (speedCharacteristic != null) {
      // We finally listen to the speed characteristic and can end the process.
      startSpeedCharacteristicListener();
      statusText = "";
      isSetUp = true;
      notifyListeners();
    }
  }

  /// retrieves the speed characteristic from all available services
  void startSpeedCharacteristicListener() {
    if (speedCharacteristic == null) return;

    // Enable notifications.
    speedCharacteristic!.setNotifyValue(true);
    // Listen to last value received.

    Positioning positioning = getIt<Positioning>();

    _speedCharacteristicListener = speedCharacteristic!.lastValueStream.listen((value) {
      final drivenDistance = _calculateDrivenDistance(value);
      PositionSource? source = positioning.positionSource;
      if (source != null) {
        SpeedSensorPositioningSource speedSensorPositioningSource = source as SpeedSensorPositioningSource;
        speedSensorPositioningSource.addDistance(drivenDistance);
      }
      notifyListeners();
    });
  }

  /// retrieves the speed characteristic from all available services
  void stopSpeedCharacteristicListener() {
    _speedCharacteristicListener?.cancel();
  }

  /// calculates the driven distance since the last update
  /// based on: wheelsize, sensor data
  /// @parameter values (data from the speed characteristic,
  /// the structure of this is described at the start of the class)
  double _calculateDrivenDistance(List<int> values) {
    log.i("calculating speed");
    log.i(values);

    // Return 0 if less then 7 elements. [a, b, c, d, e, f, g]
    if (values.length < 7) return 0;

    int rotations = values[1];

    // we have to initialize _lastNumberOfRotations when we get the first reading
    _lastNumberOfRotations ??= rotations;

    int rotationDifference = rotations - _lastNumberOfRotations!;
    // we could also check, if value[2] is greater than the last time, but this
    // implementation was done before i noticed that the sensor has a dedicated parameter for this
    if (rotationDifference < 0) {
      rotationDifference = rotationDifference + 255;
    }

    _lastNumberOfRotations = rotations;

    return wheelCircumferenceMeter * rotationDifference;
  }

  void reset() {
    device = null;
    isSetUp = false;
    loading = false;
    _scanListener?.cancel();
    _adapterStateListener?.cancel();
    _speedCharacteristicListener?.cancel();
    _scanListener = null;
    _adapterStateListener = null;
    _speedCharacteristicListener = null;
    adapterState = BluetoothAdapterState.unknown;
    speedCharacteristic = null;
    _lastNumberOfRotations = -1;
    statusText = "";
    failure = false;
  }
}
