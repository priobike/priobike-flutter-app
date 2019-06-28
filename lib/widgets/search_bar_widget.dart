import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import 'package:bike_now/blocs/route_creation_bloc.dart';



import 'package:bike_now/geo_coding/search_response.dart';

class SearchBarWidget extends StatefulWidget {
  final String hintText;

  SearchBarWidget(this.hintText);
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _SearchBarState(hintText);
  }
}

class _SearchBarState extends State<SearchBarWidget> {
  final String hintText;
  FocusNode _focus = new FocusNode();
  var txtController = new TextEditingController();


  _SearchBarState(this.hintText);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    final routeCreationBloc = Provider.of<RouteCreationBloc>(context);



    return Container(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.only(left: 20),
          decoration: BoxDecoration(
/*              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3.0,
                  spreadRadius: 0.1,
                )
              ],*/
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(5)),
              border: Border.all(
                  color: Colors.black45, width: 1, style: BorderStyle.solid)),
          child: Row(
            children: <Widget>[
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () async {
                    final Place place = await showSearch(
                        context: context,
                        delegate: PlaceSearch(),
                        query: txtController.text);
                    setState(() {
                      var i = place.displayName;
                      txtController.text = place.displayName;
                    });
                  },
                  child: TextField(
                      controller: txtController,
                      keyboardType: TextInputType.text,
                      enabled: false,
                      decoration: new InputDecoration.collapsed(
                          hintText: hintText),
                )),

              ),
              IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    txtController.text = '';
                  });
                },
              )
            ],
          ),
        ));
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
