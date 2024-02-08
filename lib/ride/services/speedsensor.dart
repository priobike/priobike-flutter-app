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
  StreamSubscription? _connectionStateListener;

  /// The speed characteristic listener.
  StreamSubscription? _speedCharacteristicListener;

  /// The connection state.
  BluetoothConnectionState connectionState = BluetoothConnectionState.disconnected;

  /// The speed characteristic.
  BluetoothCharacteristic? speedCharacteristic;

  /// The current speed.
  double speed = 0;

  /// Probably getting remove...
  int _lastNumberOfRotations = -1;
  List<int> _lastReadings = [];
  bool _ignoredReading = false;
  double _lastRotationsPerSecond = 0;
  DateTime _timeOfLastSpeedUpdate = DateTime.timestamp();

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

    // Cancel connection state listener.
    _connectionStateListener?.cancel();
  }

  void startBluetoothStateListener() {
    if (device == null) return;

    _connectionStateListener = device!.connectionState.listen((state) {
      connectionState = state;
      notifyListeners();
    });
  }

  void stopBluetoothStateListener() {
    _connectionStateListener?.cancel();
    notifyListeners();
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
      log.i(value);
      speed = _calculateSpeed(value);
      log.i(speed);
      PositionSource? source = positioning.positionSource;
      if (source != null) {
        SpeedSensorPositioningSource speedSensorPositioningSource = source as SpeedSensorPositioningSource;
        speedSensorPositioningSource.updateSpeed(speed);
      }
      notifyListeners();
    });
  }

  /// retrieves the speed characteristic from all available services
  void stopSpeedCharacteristicListener() {
    _speedCharacteristicListener?.cancel();
  }

  /// calculates the current speed
  /// based on: wheelsize, sensor data
  /// @parameter values (data from the speed characteristic,
  /// the structure of this is described at the start of the class)
  double _calculateSpeed(List<int> values) {
    log.i("calculating speed");
    log.i(values);

    // Return 0 if less then 7 elements. [a, b, c, d, e, f, g]
    if (values.length < 7) return 0;

    int rotations = values[1];

    // we have to initialize _lastNumberOfRotations when we get the first reading
    if (_lastNumberOfRotations < 0) {
      _lastNumberOfRotations = rotations;
    }

    int rotationDifference = rotations - _lastNumberOfRotations;
    // we could also check, if value[2] is greater than the last time, but this
    // implementation was done before i noticed that the sensor has a dedicated parameter for this
    if (rotationDifference < 0) {
      rotationDifference = rotationDifference + 255;
    }

    final currentTime = DateTime.timestamp();

    // time passed since the last measurement
    int timeDifferenceInMilliseconds =
        currentTime.millisecondsSinceEpoch - _timeOfLastSpeedUpdate.millisecondsSinceEpoch;
    _timeOfLastSpeedUpdate = currentTime;

    _lastNumberOfRotations = rotations;

    //log.i("🔵 rotations: $rotations");
    //log.i("🟡 rotationDifference: $rotationDifference");
    //log.i("timeDifference: $timeDifference");
    //log.i("🟣 lastRotations: $_lastRotations");

    // sometimes the sensor seems to randomly repeat the last readings exactly... so we just ignore it *once*
    if (!listEquals(values, _lastReadings)) {
      // reset flag when we get an actual new reading
      _ignoredReading = false;
    } else if (!_ignoredReading) {
      _ignoredReading = true;
      return speed;
    }

    _lastReadings = values;

    // exponential smoothing
    const smoothingFactor = 0.9;
    double rotationsPerSecond = smoothingFactor * (rotationDifference / timeDifferenceInMilliseconds * 1000) +
        (1 - smoothingFactor) * _lastRotationsPerSecond;
    // cut-off to prevent the value from shrinking way too slowly before reaching 0
    if (rotationsPerSecond < 0.01) {
      rotationsPerSecond = 0;
    }
    _lastRotationsPerSecond = rotationsPerSecond;
    //log.i("🔴 rotationsPerSecond: $rotationsPerSecond");

    const wheelCircumferenceMeter = math.pi * wheelSizeInch / 39.37;
    final speedMetersPerSecond = rotationsPerSecond * wheelCircumferenceMeter;
    // return calculated speed in km/h
    return speedMetersPerSecond * 3.6;
  }

  void reset() {
    device = null;
    isSetUp = false;
    loading = false;
    _scanListener = null;
    _connectionStateListener = null;
    _speedCharacteristicListener = null;
    connectionState = BluetoothConnectionState.disconnected;
    speedCharacteristic = null;
    speed = 0;
    _lastNumberOfRotations = -1;
    _lastReadings = [];
    _ignoredReading = false;
    _lastRotationsPerSecond = 0;
    _timeOfLastSpeedUpdate = DateTime.timestamp();
    statusText = "";
    failure = false;
  }
}
