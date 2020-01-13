import 'package:bike_now_flutter/helper/settingKeys.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart' as xml;
import 'package:bike_now_flutter/models/models.dart' as BikeNow;
import 'package:rxdart/rxdart.dart';
import 'package:geolocator/geolocator.dart';

class LocationController extends ChangeNotifier {
  var geolocator = Geolocator();
  var locationOptions = LocationOptions(
      accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 10);

  Position currentLocation = null;
  Timer timer;
  String gpsFile;
  List<xml.XmlElement> elements;
  int index = 0;

  Stream<BikeNow.LatLng> get getCurrentLocation =>
      _currentLocationSubject.stream;
  final _currentLocationSubject = BehaviorSubject<BikeNow.LatLng>();

  LocationController() {
    SharedPreferences.getInstance().then((prefs) {
      bool useFakeData = prefs.getBool(SettingKeys.isSimulator) ?? false;
      if (!useFakeData) {
        geolocator
            .getPositionStream(locationOptions)
            .listen((Position position) {
          onNewPosition(position);
        });
      } else {
        timer = Timer.periodic(Duration(seconds: 1), updateLocation);
      }
    });
  }

  void onNewPosition(Position position) {
    Map<String, double> map = Map<String, double>();
    map['latitude'] = position.latitude;
    map['longitude'] = position.longitude;
    map['accuracy'] = 0;

    map['speed'] = position.speed;
    currentLocation = Position.fromMap(map);
    _currentLocationSubject.add(
        BikeNow.LatLng(currentLocation.latitude, currentLocation.longitude));
  }

  void updateLocation(Timer timer) async {
    if (gpsFile == null) {
      gpsFile = await rootBundle.loadString('assets/gpx/HbfToAlbert20kmh.gpx');
      var document = xml.parse(gpsFile);
      elements = document.findAllElements('wpt').toList();
    }
    Map<String, double> map = Map<String, double>();
    map['latitude'] = double.parse(elements[index].getAttribute("lat"));
    map['longitude'] = double.parse(elements[index].getAttribute("lon"));
    map['accuracy'] = 0;
    map['speed'] = 20 / 3.6;
    currentLocation = Position.fromMap(map);
    _currentLocationSubject
        .add(BikeNow.LatLng(map['latitude'], map['longitude']));

    if (index < elements.length) {
      index++;
    }
  }
}
