import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'speed_sensor_extra.dart';

class GarminSpeedSensor {

  String speedSensorName = "SPD-BLE0594113";
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  List<BluetoothDevice> _connectedDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  late BluetoothDevice device;

  int? _rssi;
  int? _mtuSize;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isDiscoveringServices = false;
  bool _isConnecting = false;
  bool _isDisconnecting = false;

  BluetoothCharacteristic? speedCharacteristic;
  DateTime timeOfLastSpeedUpdate = DateTime.timestamp();
  int lastNumberOfRotations = 0;

  //enter wheel size in inch in numerator
  double wheelSizeInKm = 28 / 39370;
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
    device = _connectedDevices.firstWhere((element) => element.localName == speedSensorName);
    if( device != null) {
      return true;
    }

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      ScanResult element = _scanResults.firstWhere((element) => element.advertisementData.localName == speedSensorName);
      if(element != null) {
        FlutterBluePlus.stopScan();
        device = element.device;
      }
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15), androidUsesFineLocation: true);
    return device != null;
  }

  void _discoverServices() {
    if(device == null) {
      print("error: device = null!");
      return;
    }
    _connectionStateSubscription = device.connectionState.listen((state) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        _services = []; // must rediscover services
      }
      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await device.readRssi();
      }
    });

    _mtuSubscription = device.mtu.listen((value) {
      _mtuSize = value;
    });
    _isConnectingSubscription = device.isConnecting.listen((value) {
      _isConnecting = value;
    });

    _isDisconnectingSubscription = device.isDisconnecting.listen((value) {
      _isDisconnecting = value;
    });
  }

  @override
  Future<bool> initSpeedSensor() async {
    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
    });

    if(_adapterState != BluetoothAdapterState.on) {
      print("bluetooth turned off");
      return false;

    }

    if(!await _initConnectedDevices()) {
      return false;
    }
    _discoverServices();
    _onConnectPressed();
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
      await device.connectAndUpdateStream();
      print("connection success");
    } catch (e) {
      if (e is FlutterBluePlusException && e.code == FbpErrorCode.createBondFailed) {
        // ignore connections canceled by the user
      } else {
        print("error connecting");
      }
    }
    _getSpeedCharacteristic();
  }

  Future _onDiscoverServicesPressed() async {
    try {
      _services = await device.discoverServices();
      print("got service successfully");
    } catch (e) {
      print("error getting service");
    }
  }

  void _getSpeedCharacteristic() async {
    await _onDiscoverServicesPressed();
    Iterator<BluetoothService> serviceIter = _services.iterator;

    BluetoothCharacteristic characteristic;
    while(serviceIter.moveNext()) {
      BluetoothService service = serviceIter.current;
      if(service.uuid.toString().toUpperCase() == "00001816-0000-1000-8000-00805F9B34FB") {
        //correct service found
        Iterator<BluetoothCharacteristic> characteristicsIter = service.characteristics.iterator;
        while(characteristicsIter.moveNext()) {
          if(characteristicsIter.current.uuid.toString().toUpperCase() == "00002A5B-0000-1000-8000-00805F9B34FB") {
            //correct characteristic found
            speedCharacteristic =  characteristicsIter.current;
            break;
          }
        }
        break;
      }
    }

    await speedCharacteristic!.setNotifyValue(speedCharacteristic!.isNotifying == false);
    _lastValueSubscription = speedCharacteristic!.lastValueStream.listen((value) {
      _speed = _calculateSpeed(value);
    });
  }

  double _calculateSpeed(List<int> values) {
    print("calculating speed");
    print(values);
    int rotations = values[1];

    int rotationDifference = rotations - lastNumberOfRotations;
    if(rotationDifference < 0) {
      rotationDifference = rotationDifference + 255;
    }

    //in milliseconds
    int timeDifferenceInMilliseconds = DateTime.timestamp().millisecondsSinceEpoch - timeOfLastSpeedUpdate.millisecondsSinceEpoch;
    //hours
    double timeDifference = timeDifferenceInMilliseconds / 3600000;
    lastNumberOfRotations = rotations;
    timeOfLastSpeedUpdate = DateTime.timestamp();
    return (rotationDifference * wheelSizeInKm) / timeDifference;
  }

  double getSpeed() {
    return _speed;
  }
}
