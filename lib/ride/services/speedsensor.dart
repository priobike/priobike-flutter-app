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

const String _characteristicsUuid = "00002A5B-0000-1000-8000-00805F9B34FB";

const double _wheelSizeInch = 28;
const _wheelCircumferenceMeter = math.pi * _wheelSizeInch / 39.37;

class SpeedSensor with ChangeNotifier {
  /// Logger for this class.
  final log = Logger("Speed Sensor Service");

  /// The BluetoothDevice
  BluetoothDevice? _device;

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
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  /// The speed characteristic.
  BluetoothCharacteristic? _speedCharacteristic;

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
      if (bluetoothDevice.platformName == _speedSensorName) _device = bluetoothDevice;
    }

    // Check device connected.
    if (!(_device == null)) {
      log.i("device already connected, yay");
      statusText = "Sensor gefunden.";
      notifyListeners();
      _connectSpeedSensor();
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
      _device = sensorFound.device;
      log.i("found speed sensor!");
      statusText = "Sensor gefunden.";
      FlutterBluePlus.stopScan();
      loading = false;
      notifyListeners();

      // Next step. Connect to sensor.
      _connectSpeedSensor();
    });

    // start bluetooth scan
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    // Wait 10 seconds because startScan can't be await.
    await Future.delayed(const Duration(seconds: 10));

    // Stop listening after scan unsuccessful.
    if (_device == null) {
      _scanListener?.cancel();
      _scanListener = null;
      loading = false;
      statusText = "Sensor wurde nicht gefunden.";
      failure = true;
      notifyListeners();
    }
  }

  void _stopScanningDevices() {
    FlutterBluePlus.stopScan();
    _scanListener?.cancel();
    _scanListener = null;
    loading = false;
    notifyListeners();
  }

  /// tries connecting to the speed sensor
  /// Note: _device has to be initialized
  Future<void> _connectSpeedSensor() async {
    if (_device == null) return;
    loading = true;
    statusText = "Verbinde Sensor";
    notifyListeners();

    await _device!.connect();

    loading = false;
    notifyListeners();

    if (_device!.isConnected) {
      statusText = "Sensor verbunden";
      notifyListeners();
      _discoverServicesOfDevice();
    } else {
      statusText = "Sensor konnte nicht verbunden werden";
      failure = true;
      notifyListeners();
    }
  }

  /// tries connecting to the speed sensor
  /// Note: _device has to be initialized
  Future<void> _disconnectSpeedSensor() async {
    if (_device == null) return;
    await _device!.disconnect();
  }

  void _startBluetoothStateListener() {
    _adapterStateListener = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (_adapterState == BluetoothAdapterState.off) {
        isSetUp = false;
        failure = true;
      }
      notifyListeners();
    });
  }

  void _stopBluetoothStateListener() {
    _adapterStateListener?.cancel();
  }

  /// discovers all services of connected device
  /// Note: _device has to be initialized
  Future<void> _discoverServicesOfDevice() async {
    if (_device == null) return;
    if (!_device!.isConnected) return;

    loading = true;
    statusText = "Suche nach Speed Service";
    notifyListeners();

    List<BluetoothService> services = await _device!.discoverServices();

    statusText = "Services werden geprüft";
    notifyListeners();

    log.i("got services successfully");
    log.i(services);
    notifyListeners();

    // Search speed characteristic.
    for (BluetoothService bluetoothService in services) {
      for (BluetoothCharacteristic bluetoothCharacteristic in bluetoothService.characteristics) {
        if (bluetoothCharacteristic.uuid.toString().toUpperCase() == _characteristicsUuid) {
          _speedCharacteristic = bluetoothCharacteristic;
          notifyListeners();
        }
      }
    }

    loading = false;
    statusText = _speedCharacteristic != null ? "Service gefunden" : "Service nicht gefunden";
    notifyListeners();

    if (_speedCharacteristic != null) {
      // We finally listen to the speed characteristic and can end the process.
      _startSpeedCharacteristicListener();
      statusText = "";
      isSetUp = true;
      notifyListeners();
    }
  }

  /// retrieves the speed characteristic from all available services
  void _startSpeedCharacteristicListener() {
    if (_speedCharacteristic == null) return;

    // Enable notifications.
    _speedCharacteristic!.setNotifyValue(true);
    // Listen to last value received.

    Positioning positioning = getIt<Positioning>();

    _speedCharacteristicListener = _speedCharacteristic!.lastValueStream.listen((value) {
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
  void _stopSpeedCharacteristicListener() {
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

    if (rotationDifference < 0) {
      // we could also check, if value[2] is greater than the last time, but this
      // implementation was done before i noticed that the sensor has a dedicated parameter for this
      rotationDifference = rotationDifference + 255;
    } else if (rotationDifference == 0) {
      // if the difference is 0, no complete rotation was made
      // Therefore we used the angle difference to calculate the driven distance
      final angleDifference = values[4];
      return _wheelCircumferenceMeter * (angleDifference / 360);
    }

    _lastNumberOfRotations = rotations;

    return _wheelCircumferenceMeter * rotationDifference;
  }

  void reset() {
    _disconnectSpeedSensor();
    _device = null;
    isSetUp = false;
    loading = false;
    _scanListener?.cancel();
    _adapterStateListener?.cancel();
    _speedCharacteristicListener?.cancel();
    _scanListener = null;
    _adapterStateListener = null;
    _speedCharacteristicListener = null;
    _adapterState = BluetoothAdapterState.unknown;
    _speedCharacteristic = null;
    _lastNumberOfRotations = -1;
    statusText = "";
    failure = false;
  }
}
