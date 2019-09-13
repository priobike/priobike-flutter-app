import 'package:bike_now_flutter/configuration.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsBloc extends ChangeNotifier {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  // Pref STREAMS
  Stream<int> get maxSpeed => _maxSpeedSubject.stream;
  final _maxSpeedSubject = BehaviorSubject<int>();
  Sink<int> get setMaxSpeed => _setMaxSpeedController.sink;
  final _setMaxSpeedController = StreamController<int>();

  Stream<bool> get racer => _racerSubject.stream;
  final _racerSubject = BehaviorSubject<bool>();
  Sink<bool> get setRacer => _setRacerController.sink;
  final _setRacerController = StreamController<bool>();

  Stream<bool> get dynamicLocation => _dynamicLocationSubject.stream;
  final _dynamicLocationSubject = BehaviorSubject<bool>();
  Sink<bool> get setDynamicLocation => _setDynamicLocationController.sink;
  final _setDynamicLocationController = StreamController<bool>();

  Stream<bool> get optimiyeSystemTime => _optimiyeSystemTimeSubject.stream;
  final _optimiyeSystemTimeSubject = BehaviorSubject<bool>();
  Sink<bool> get setOptimiyeSystemTime => _setOptimiyeSystemTimeController.sink;
  final _setOptimiyeSystemTimeController = StreamController<bool>();

  Stream<bool> get slowlyHideTrafficLightPhase =>
      _slowlyHideTrafficLightPhaseSubject.stream;
  final _slowlyHideTrafficLightPhaseSubject = BehaviorSubject<bool>();
  Sink<bool> get setSlowlyHideTrafficLightPhase =>
      _setSlowlyHideTrafficLightPhaseController.sink;
  final _setSlowlyHideTrafficLightPhaseController = StreamController<bool>();

  Stream<bool> get showGPSAccuracy => _showGPSAccuracySubject.stream;
  final _showGPSAccuracySubject = BehaviorSubject<bool>();
  Sink<bool> get setShowGPSAccuracy => _setShowGPSAccuracyController.sink;
  final _setShowGPSAccuracyController = StreamController<bool>();

  Stream<bool> get debugMode => _debugModeSubject.stream;
  final _debugModeSubject = BehaviorSubject<bool>();
  Sink<bool> get setDebugMode => _setDebugModeController.sink;
  final _setDebugModeController = StreamController<bool>();

  Stream<int> get maxAccuracy => _maxAccuracySubject.stream;
  final _maxAccuracySubject = BehaviorSubject<int>();
  Sink<int> get setMaxAccuracy => _setMaxAccuracyController.sink;
  final _setMaxAccuracyController = StreamController<int>();

  Stream<int> get minDistance => _minDistanceSubject.stream;
  final _minDistanceSubject = BehaviorSubject<int>();
  Sink<int> get setMinDistance => _setMinDistanceController.sink;
  final _setMinDistanceController = StreamController<int>();

  Stream<int> get crossQuantity => _crossQuantitySubject.stream;
  final _crossQuantitySubject = BehaviorSubject<int>();
  Sink<int> get setCrossQuantity => _setCrossQuantityController.sink;
  final _setCrossQuantityController = StreamController<int>();

  Stream<int> get accuracyModifier => _accuracyModifierSubject.stream;
  final _accuracyModifierSubject = BehaviorSubject<int>();
  Sink<int> get setAccuracyModifier => _setAccuracyModifierController.sink;
  final _setAccuracyModifierController = StreamController<int>();

  Stream<String> get password => _passwordSubject.stream;
  final _passwordSubject = BehaviorSubject<String>();
  Sink<String> get setPassword => _setPasswordController.sink;
  final _setPasswordController = StreamController<String>();

  Stream<bool> get pushLocations => _pushLocationsSubject.stream;
  final _pushLocationsSubject = BehaviorSubject<bool>();
  Sink<bool> get setPushLocations => _setPushLocationsController.sink;
  final _setPushLocationsController = StreamController<bool>();

  Stream<bool> get simulator => _simulatorSubject.stream;
  final _simulatorSubject = BehaviorSubject<bool>();
  Sink<bool> get setSimulator => _setSimulatorController.sink;
  final _setSimulatorController = StreamController<bool>();

  SettingsBloc() {
    addSetterToStreamController();
    fetchSettings();
  }

  void _setMaxSpeed(int maxSpeed) async {
    final SharedPreferences prefs = await _prefs;
    final prefIsSet = await prefs.setInt("maxSpeed", maxSpeed);
    if (prefIsSet) {
      _maxSpeedSubject.add(maxSpeed);
    } else {
      throw new Exception('maxSpeed Pref cannot be set');
    }
  }

  void _setRacer(bool racer) async {
    final SharedPreferences prefs = await _prefs;
    final prefIsSet = await prefs.setBool("racer", racer);
    if (prefIsSet) {
      _racerSubject.add(racer);
    } else {
      throw new Exception('racer Pref cannot be set');
    }
  }

  void _setDynamicLocation(bool dynamicLocation) async {
    final SharedPreferences prefs = await _prefs;
    final prefIsSet = await prefs.setBool("dynamicLocation", dynamicLocation);
    if (prefIsSet) {
      _dynamicLocationSubject.add(dynamicLocation);
    } else {
      throw new Exception('setDynamicLocation Pref cannot be set');
    }
  }

  void _setOptimiyeSystemTime(bool optimiyeSystemTime) async {
    final SharedPreferences prefs = await _prefs;
    final prefIsSet =
        await prefs.setBool("optimizeSystemTime", optimiyeSystemTime);
    if (prefIsSet) {
      _optimiyeSystemTimeSubject.add(optimiyeSystemTime);
    } else {
      throw new Exception('optimizeSystemTime Pref cannot be set');
    }
  }

  void _setSlowlyHideTrafficLightPhase(bool slowlyHideTrafficLightPhase) async {
    final SharedPreferences prefs = await _prefs;
    final prefIsSet = await prefs.setBool(
        "slowlyHideTrafficLightPhase", slowlyHideTrafficLightPhase);
    if (prefIsSet) {
      _slowlyHideTrafficLightPhaseSubject.add(slowlyHideTrafficLightPhase);
    } else {
      throw new Exception('slowlyHideTrafficLightPhase Pref cannot be set');
    }
  }

  void _setShowGPSAccuracy(bool showGPSAccuracy) async {
    final SharedPreferences prefs = await _prefs;
    final prefIsSet = await prefs.setBool("showGPSAccuracy", showGPSAccuracy);
    if (prefIsSet) {
      _showGPSAccuracySubject.add(showGPSAccuracy);
    } else {
      throw new Exception('showGPSAccuracy Pref cannot be set');
    }
  }

  void _setDebugMode(bool debugMode) async {
    final SharedPreferences prefs = await _prefs;
    final prefIsSet = await prefs.setBool("debugMode", debugMode);
    if (prefIsSet) {
      _debugModeSubject.add(debugMode);
    } else {
      throw new Exception('debugMode Pref cannot be set');
    }
  }

  void _setMaxAccuracy(int maxAccuracy) async {
    final SharedPreferences prefs = await _prefs;
    final prefIsSet = await prefs.setInt("maxAccuracy", maxAccuracy);
    if (prefIsSet) {
      _maxAccuracySubject.add(maxAccuracy);
    } else {
      throw new Exception('maxAccuracy Pref cannot be set');
    }
  }

  void _setMinDistance(int minDistance) async {
    final SharedPreferences prefs = await _prefs;
    final prefIsSet = await prefs.setInt("minDistance", minDistance);
    if (prefIsSet) {
      _minDistanceSubject.add(minDistance);
    } else {
      throw new Exception('minDistance Pref cannot be set');
    }
  }

  void _setCrossQuantity(int crossQuantity) async {
    final SharedPreferences prefs = await _prefs;
    final prefIsSet = await prefs.setInt("crossQuantity", crossQuantity);
    if (prefIsSet) {
      _crossQuantitySubject.add(crossQuantity);
    } else {
      throw new Exception('crossQuantity Pref cannot be set');
    }
  }

  void _setAccuracyModifier(int accuracyModifier) async {
    final SharedPreferences prefs = await _prefs;
    final prefIsSet = await prefs.setInt("accuracyModifier", accuracyModifier);
    if (prefIsSet) {
      _accuracyModifierSubject.add(accuracyModifier);
    } else {
      throw new Exception('accuracyModifier Pref cannot be set');
    }
  }

  void _setPassword(String password) async {
    final SharedPreferences prefs = await _prefs;
    final prefIsSet = await prefs.setString("password", password);
    if (prefIsSet) {
      _passwordSubject.add(password);
    } else {
      throw new Exception('password Pref cannot be set');
    }
  }

  void _setPushLocations(bool pushLocations) async {
    final SharedPreferences prefs = await _prefs;
    final prefIsSet = await prefs.setBool("pushLocations", pushLocations);
    if (prefIsSet) {
      _pushLocationsSubject.add(pushLocations);
    } else {
      throw new Exception('debugMode Pref cannot be set');
    }
  }

  void _setSimulator(bool simulator) async {
    final SharedPreferences prefs = await _prefs;
    final prefIsSet = await prefs.setBool(SettingKeys.simulator, simulator);
    if (prefIsSet) {
      _simulatorSubject.add(simulator);
    } else {
      throw new Exception('debugMode Pref cannot be set');
    }
  }

  void addSetterToStreamController() {
    _setMaxSpeedController.stream.listen(_setMaxSpeed);
    _setRacerController.stream.listen(_setRacer);
    _setDynamicLocationController.stream.listen(_setDynamicLocation);
    _setOptimiyeSystemTimeController.stream.listen(_setOptimiyeSystemTime);
    _setSlowlyHideTrafficLightPhaseController.stream
        .listen(_setSlowlyHideTrafficLightPhase);
    _setShowGPSAccuracyController.stream.listen(_setShowGPSAccuracy);
    _setDebugModeController.stream.listen(_setDebugMode);
    _setMaxAccuracyController.stream.listen(_setMaxAccuracy);
    _setMinDistanceController.stream.listen(_setMinDistance);
    _setCrossQuantityController.stream.listen(_setCrossQuantity);
    _setAccuracyModifierController.stream.listen(_setAccuracyModifier);
    _setPasswordController.stream.listen(_setPassword);
    _setPushLocationsController.stream.listen(_setPushLocations);
    _setSimulatorController.stream.listen(_setSimulator);
  }

  void fetchSettings() {
    //FetchPrefs
    _prefs.then((SharedPreferences prefs) {
      _maxSpeedSubject.add(prefs.getInt('maxSpeed') ?? 0);
    });

    _prefs.then((SharedPreferences prefs) {
      _racerSubject.add(prefs.getBool('racer') ?? false);
    });

    _prefs.then((SharedPreferences prefs) {
      _dynamicLocationSubject.add(prefs.getBool('dynamicLocation') ?? false);
    });

    _prefs.then((SharedPreferences prefs) {
      _optimiyeSystemTimeSubject
          .add(prefs.getBool('optimizeSystemTime') ?? false);
    });

    _prefs.then((SharedPreferences prefs) {
      _slowlyHideTrafficLightPhaseSubject
          .add(prefs.getBool('slowlyHideTrafficLightPhase') ?? false);
    });

    _prefs.then((SharedPreferences prefs) {
      _showGPSAccuracySubject.add(prefs.getBool('showGPSAccuracy') ?? false);
    });

    _prefs.then((SharedPreferences prefs) {
      _debugModeSubject.add(prefs.getBool('debugMode') ?? false);
    });

    _prefs.then((SharedPreferences prefs) {
      _maxAccuracySubject.add(prefs.getInt('maxAccuracy') ?? 0);
    });

    _prefs.then((SharedPreferences prefs) {
      _minDistanceSubject.add(prefs.getInt('minDistance') ?? 0);
    });

    _prefs.then((SharedPreferences prefs) {
      _crossQuantitySubject.add(prefs.getInt('crossQuantity') ?? 0);
    });

    _prefs.then((SharedPreferences prefs) {
      _accuracyModifierSubject.add(prefs.getInt('accuracyModifier') ?? 0);
    });

    _prefs.then((SharedPreferences prefs) {
      _passwordSubject.add(prefs.getString('password') ?? "");
    });

    _prefs.then((SharedPreferences prefs) {
      _pushLocationsSubject.add(prefs.getBool('pushLocations') ?? false);
    });

    _prefs.then((SharedPreferences prefs) {
      _simulatorSubject.add(prefs.getBool(SettingKeys.simulator) ?? false);
    });
  }
}
