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

class PlaceSearch extends SearchDelegate<Place> {


  static Future<PlaceList> fetchPlaceList(String adress) async {
    http.Response response = await http.get('https://nominatim.openstreetmap.org/search/{$adress}%3C?format=json');
    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON
      return  PlaceList.fromJson(json.decode(response.body) as List);
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to fetch PlaceList-JSON');
    }
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },

    );
  }
  @override
  Widget buildResults(BuildContext context) {

    // TODO: implement buildResults
    return ListView(
      children: <Widget>[

      ],
    );
  }
  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: implement buildSuggestions
    return FutureBuilder<PlaceList>(
      future: fetchPlaceList(query),
      builder: (BuildContext context, AsyncSnapshot<PlaceList> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return Text('Press button to start.');
          case ConnectionState.active:
          case ConnectionState.waiting:
            return ListTile(title: Text('Awaiting result...'));
          case ConnectionState.done:
            if (snapshot.hasError)
              return Text('Error: ${snapshot.error}');
            return Container(
                padding: EdgeInsets.only(top: 8),
                child: ListView(
                  children: <Widget>[
                    for(var place in snapshot.data.places) ListTile(
                      title: Text(place.displayName),
                      subtitle: Text('Lat: ' + place.lat.toString() + ' Long: ' + place.lon.toString()),
                      onTap: () {
                        close(context, place);
                      },
                    )
                  ],

                ));
        //Text('Result: ${snapshot.data}');
        }
      },
    );
  }

}