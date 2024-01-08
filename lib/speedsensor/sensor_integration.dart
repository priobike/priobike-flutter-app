import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'utils.dart';

import 'package:priobike/logging/logger.dart';
import 'package:priobike/common/layout/dialog.dart';
import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';

final Map<DeviceIdentifier, StreamControllerReemit<bool>> _cglobal = {};
final Map<DeviceIdentifier, StreamControllerReemit<bool>> _dglobal = {};

final log = Logger("sensor_integration.dart");

class GarminSpeedSensor extends StatefulWidget {

  final Positioning positioning;
  final AsyncCallback callback;
  const GarminSpeedSensor({super.key, required this.positioning, required this.callback});
  @override
  State<GarminSpeedSensor> createState() => _GarminSpeedSensorState();
}
class _GarminSpeedSensorState extends State<GarminSpeedSensor> {

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

  BluetoothDevice? _device;

  int? _rssi;
  int? _mtuSize;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isConnecting = false;
  bool _isDisconnecting = false;
  bool _isDiscoveringServices = false;

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

  void _initConnectedDevices() async {
    if(!(_device == null)) {
      log.i("device already connected, yay");
      _discoverServices();
      return;
    } else {
      log.i("device not connected yet.");
    }
    log.i("initalizing connected devices");
    FlutterBluePlus.systemDevices.then((devices) {
      _connectedDevices = devices;
      //setState(() {});
    });
    try {
      _device = _connectedDevices.firstWhere((element) => element.platformName == _speedSensorName);
      _discoverServices();
      return;
    } catch (e) {
      log.i("speed sensor not in connected devices");
    }

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      log.i(_scanResults);
      try {
        ScanResult element = _scanResults.firstWhere((element) =>
        element.advertisementData.advName == _speedSensorName);
        FlutterBluePlus.stopScan();
        _device = element.device;
        log.i("found speed sensor!");
        _discoverServices();
      } catch (e) {
        log.i("speed sensor not in scan results");
      }
      setState(() {});
    });
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      setState(() {});
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15), continuousUpdates: true, androidUsesFineLocation: true);
  }

  void _discoverServices() {
    _connectionStateSubscription = _device!.connectionState.listen((state) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        _services = []; // must rediscover services
      }
      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await _device!.readRssi();
      }
      setState(() {});
    });

    _mtuSubscription = _device!.mtu.listen((value) {
      _mtuSize = value;
      setState(() {});
    });
    _isConnectingSubscription = _device!.isConnecting.listen((value) {
      _isConnecting = value;
      setState(() {});
    });

    _isDisconnectingSubscription = _device!.isDisconnecting.listen((value) {
      _isDisconnecting = value;
      setState(() {});
    });

    _onConnectPressed();
  }

  void initBluetoothForSpeedSensor() {
    log.i("initializing bluetooth for speed sensor");
    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if(_adapterState == BluetoothAdapterState.off) {
        log.i("ERROR: bluetooth turned off");
        if (Platform.isAndroid) {
          log.i("turning bluetooth on");
          FlutterBluePlus.turnOn();
        }
      }
      if(_adapterState == BluetoothAdapterState.on) {
        _initConnectedDevices();
      }
      setState(() {});
    });
  }

  void updatePositioningViaSpeedSensor() {
    getSpeed();
    widget.callback;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initBluetoothForSpeedSensor();
    widget.positioning.addListener(updatePositioningViaSpeedSensor);
  }

  @override
  void dispose() {
    super.dispose();
    _connectionStateSubscription.cancel();
    _mtuSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    _lastValueSubscription.cancel();
    _adapterStateStateSubscription.cancel();
    widget.positioning.removeListener(updatePositioningViaSpeedSensor);
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Future _onConnectPressed() async {
    try {
      await _device!.connectAndUpdateStream();
      log.i("connection success");
      _getSpeedCharacteristic();
    } catch (e) {
      log.i("error connecting");
    }
  }

  Future<void> _onDiscoverServicesPressed() async {
    setState(() {
      _isDiscoveringServices = true;
    });
    try {
      _services = await _device!.discoverServices(subscribeToServicesChanged: false);
      log.i("got services successfully");
      log.i(_services);
    } catch (e) {
      log.i("error getting service");
    }
    setState(() {
      _isDiscoveringServices = false;
    });
  }

  void _getSpeedCharacteristic() async {
    await _onDiscoverServicesPressed();
    Iterator<BluetoothService> serviceIter = _services.iterator;

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
            _speedCharacteristic = characteristicsIter.current;
            break;
          }
        }
        break;
      }
    }
    if(!(_speedCharacteristic == null)) {
      _speedCharacteristic!.setNotifyValue(_speedCharacteristic!.isNotifying == false);
      _lastValueSubscription = _speedCharacteristic!.lastValueStream.listen((value) {
        _speed = _calculateSpeed(value);
        log.i(_speed);
        setState(() {});
      });
    }
    setState(() {});
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
      useRootNavigator: false,
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

  @override
  Widget build(BuildContext context) {
    return Text(_speed.toString());
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
