import 'package:bike_now/configuration.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart' as xml;
import 'package:bike_now/models/models.dart' as BikeNow;
import 'package:rxdart/rxdart.dart';

class LocationController extends ChangeNotifier {
  var location = new Location();
  LocationData currentLocation = null;
  Timer timer;
  String gpsFile;
  List<xml.XmlElement> elements;
  int index = 0;

  Stream<BikeNow.LatLng> get getCurrentLocation =>
      _currentLocationSubject.stream;
  final _currentLocationSubject = BehaviorSubject<BikeNow.LatLng>();

  LocationController() {
    SharedPreferences.getInstance().then((prefs) {
      bool useFakeData = prefs.getBool(SettingKeys.simulator);
      if (!useFakeData) {
        location.onLocationChanged().listen((LocationData currentLocation) {
          this.currentLocation = currentLocation;
          _currentLocationSubject.add(BikeNow.LatLng(
              currentLocation.latitude, currentLocation.longitude));
        });
      } else {
        timer = Timer.periodic(Duration(seconds: 1), updateLocation);
      }
    });
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
    currentLocation = LocationData.fromMap(map);
    _currentLocationSubject
        .add(BikeNow.LatLng(map['latitude'], map['longitude']));

    if (index < elements.length) {
      index++;
    }
  }
}
