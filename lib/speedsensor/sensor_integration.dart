import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'utils.dart';

import 'package:priobike/logging/logger.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';

final Map<DeviceIdentifier, StreamControllerReemit<bool>> _cglobal = {};
final Map<DeviceIdentifier, StreamControllerReemit<bool>> _dglobal = {};

final log = Logger("sensor_integration.dart");

class GarminSpeedSensor {

  final String _speedSensorName = "SPD-BLE0594113";
  final String _serviceUuid = "00001816-0000-1000-8000-00805F9B34FB";
  final String _characteristicsUuid = "00002A5B-0000-1000-8000-00805F9B34FB";

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  List<BluetoothDevice> _connectedDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  late BluetoothDevice _device;

  int? _rssi;
  int? _mtuSize;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isConnecting = false;
  bool _isDisconnecting = false;

  BluetoothCharacteristic? _speedCharacteristic;
  DateTime _timeOfLastSpeedUpdate = DateTime.timestamp();
  int _lastNumberOfRotations = 0;

  //enter wheel size in inch in numerator
  final double _wheelSizeInKm = 28 / 39370;
  double _speed = 0;

  late StreamSubscription<List<int>> _lastValueSubscription;
  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  late StreamSubscription<bool> _isConnectingSubscription;
  late StreamSubscription<bool> _isDisconnectingSubscription;
  late StreamSubscription<int> _mtuSubscription;

  Future<bool> _initConnectedDevices() async {
    FlutterBluePlus.systemDevices.then((devices) {
      _connectedDevices = devices;
    });
    try {
      _device = _connectedDevices.firstWhere((element) => element.localName == _speedSensorName);
      return true;
    } catch (e) {
      log.i("speed sensor not in connected devices");
    }

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      try {
        ScanResult element = _scanResults.firstWhere((element) =>
        element.advertisementData.localName == _speedSensorName);
        FlutterBluePlus.stopScan();
        _device = element.device;
        log.i("found speed sensor!");
        _discoverServices();
      } catch (e) {
        log.i("speed sensor not in scan results");
      }
    });
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15), androidUsesFineLocation: true);
    return true;
  }

  void _discoverServices() {
    _connectionStateSubscription = _device.connectionState.listen((state) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        _services = []; // must rediscover services
      }
      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await _device.readRssi();
      }
    });

    _mtuSubscription = _device.mtu.listen((value) {
      _mtuSize = value;
    });
    _isConnectingSubscription = _device.isConnecting.listen((value) {
      _isConnecting = value;
    });

    _isDisconnectingSubscription = _device.isDisconnecting.listen((value) {
      _isDisconnecting = value;
    });

    _onConnectPressed();
  }

  void _checkPerm() async {
    var status = await Permission.bluetooth.status;
    if (status.isDenied) {
      log.i("bluetooth access denied");
      await Permission.bluetooth.request();
    }

    if (await Permission.bluetooth.status.isPermanentlyDenied) {
      log.i("bluetooth permanently denied");
      openAppSettings();
    }

  }

  @override
  Future<bool> initSpeedSensor(BuildContext context) async {
    log.i("initializing speed sensor");
    Navigator.of(context).pop();
    showSpeedSensorInitDialog(context);
    _checkPerm();

    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
    });

    if(_adapterState != BluetoothAdapterState.on) {
      log.i("ERROR: bluetooth turned off");
      if (Platform.isAndroid) {
        log.i("turning bluetooth on");
        await FlutterBluePlus.turnOn();
        _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
          _adapterState = state;
        });
      }
    }
    if(_adapterState != BluetoothAdapterState.on) {
      log.i("ERROR: Aborting connecting to Sensor!");
      return false;
    }
    if(!await _initConnectedDevices()) {
      log.i("ERROR: speed sensor not found!");
      return false;
    }
    log.i("speed sensor initialized");
    return true;
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    _mtuSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    _lastValueSubscription.cancel();
    _adapterStateStateSubscription.cancel();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Future _onConnectPressed() async {
    try {
      await _device.connectAndUpdateStream();
      log.i("connection success");
      _getSpeedCharacteristic();
    } catch (e) {
      log.i("error connecting");
    }
  }

  Future _onDiscoverServicesPressed() async {
    try {
      _services = await _device.discoverServices();
      log.i("got services successfully");
      log.i(_services);
    } catch (e) {
      log.i("error getting service");
    }
  }

  void _getSpeedCharacteristic() async {
    await _onDiscoverServicesPressed();
    Iterator<BluetoothService> serviceIter = _services.iterator;

    BluetoothCharacteristic characteristic;
    while(serviceIter.moveNext()) {
      BluetoothService service = serviceIter.current;
      if(service.uuid.toString().toUpperCase() == _serviceUuid) {
        log.i("found correct service");
        //correct service found
        Iterator<BluetoothCharacteristic> characteristicsIter = service.characteristics.iterator;
        while(characteristicsIter.moveNext()) {
          if(characteristicsIter.current.uuid.toString().toUpperCase() == _characteristicsUuid) {
            //correct characteristic found
            log.i("found correct characteristics");
            _speedCharacteristic =  characteristicsIter.current;
            break;
          }
        }
        break;
      }
    }

    await _speedCharacteristic!.setNotifyValue(_speedCharacteristic!.isNotifying == false);
    _lastValueSubscription = _speedCharacteristic!.lastValueStream.listen((value) {
      _speed = _calculateSpeed(value);
      log.i(_speed);
    });
  }

  double _calculateSpeed(List<int> values) {
    log.i("calculating speed");
    log.i(values);
    int rotations = values[1];

    int rotationDifference = rotations - _lastNumberOfRotations;
    if(rotationDifference < 0) {
      rotationDifference = rotationDifference + 255;
    }

    //in milliseconds
    int timeDifferenceInMilliseconds = DateTime.timestamp().millisecondsSinceEpoch - _timeOfLastSpeedUpdate.millisecondsSinceEpoch;
    //hours
    double timeDifference = timeDifferenceInMilliseconds / 3600000;
    _lastNumberOfRotations = rotations;
    _timeOfLastSpeedUpdate = DateTime.timestamp();
    return (rotationDifference * _wheelSizeInKm) / timeDifference;
  }

  double getSpeed() {
    log.i("current speed: $_speed km/h");
    return _speed;
  }

  void showSpeedSensorInitDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      pageBuilder: (BuildContext dialogContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return DialogLayout(
          title: "Verbindung zu Speed Sensor wird aufgebaut",
          text: "Wähle bitte den Speed Sensor aus. Wird er nicht angezeigt, dann vergewissere dich, dass Bluetooth angeschalten und alle nötigen Berechtigungen erteilt sind.",
          icon: Icons.speed,
          iconColor: Theme.of(context).colorScheme.primary,
          actions: [
            BigButtonPrimary(
              label: 'Auswählen',
              onPressed: () => log.i("button pressed"),
              boxConstraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
            ),
          ],
        );
      },
    );
  }
}


/// connect & disconnect + update stream
extension Extra on BluetoothDevice {
  // convenience
  StreamControllerReemit<bool> get _cstream {
    _cglobal[remoteId] ??= StreamControllerReemit(initialValue: false);
    return _cglobal[remoteId]!;
  }

  // convenience
  StreamControllerReemit<bool> get _dstream {
    _dglobal[remoteId] ??= StreamControllerReemit(initialValue: false);
    return _dglobal[remoteId]!;
  }

  // get stream
  Stream<bool> get isConnecting {
    return _cstream.stream;
  }

  // get stream
  Stream<bool> get isDisconnecting {
    return _dstream.stream;
  }

  // connect & update stream
  Future<void> connectAndUpdateStream() async {
    _cstream.add(true);
    try {
      await connect();
    } finally {
      _cstream.add(false);
    }
  }

  // disconnect & update stream
  Future<void> disconnectAndUpdateStream({bool queue = true}) async {
    _dstream.add(true);
    try {
      await disconnect();
    } finally {
      _dstream.add(false);
    }
  }
}
