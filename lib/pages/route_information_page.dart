import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';


import 'package:bike_now/geo_coding/search_response.dart';
import 'package:bike_now/widgets/search_bar_widget.dart';
import 'package:bike_now/widgets/mapbox_widget.dart';

class MapNotifier with ChangeNotifier {
  Place _targetPlace;

  Place get targetPlace => _targetPlace;

  set targetPlace(Place place){
    _targetPlace = place;
    notifyListeners();
  }

}

class RouteInformationPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ChangeNotifierProvider(
        builder: (context) => MapNotifier(),
        child: Stack(
          children: <Widget>[
            MapBoxWidget(
            ),
            Positioned(
              top: 35,
              left: 8,
              right: 8,
              child: SearchBarWidget('Schnellste Route'),
            )
          ],
        ),
      ),
    );
  }


  static Future<PlaceList> fetchPlaceList(String adress) async {
    http.Response response = await http.get('https://nominatim.openstreetmap.org/search/{$adress}%3C?format=json');
    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON
      return PlaceList.fromJson(json.decode(response.body) as List);
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to fetch PlaceList-JSON');
    }
  }
}

