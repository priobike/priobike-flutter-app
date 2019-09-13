import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

import 'package:bike_now_flutter/websocket/web_socket_service.dart';
import 'package:bike_now_flutter/server_response/websocket_response.dart';
import 'package:bike_now_flutter/websocket/web_socket_method.dart';
import 'package:bike_now_flutter/websocket/websocket_commands.dart';

import 'package:bike_now_flutter/geo_coding/address_to_location_response.dart';
import 'package:bike_now_flutter/configuration.dart';
import 'package:bike_now_flutter/blocs/bloc_manager.dart';

class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final ValueChanged<Place> onValueChanged;
  final Stream<String> txt;
  final Stream<bool> simulatorPref;

  SearchBarWidget(this.hintText, this.onValueChanged, this.txt,
      [this.simulatorPref]);
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _SearchBarState(hintText, txt);
  }
}

class _SearchBarState extends State<SearchBarWidget> {
  final String hintText;
  FocusNode _focus = new FocusNode();
  var txtController = new TextEditingController();
  final Stream<String> txt;
  bool simulatorPref = true;

  _SearchBarState(
    this.hintText,
    this.txt,
  );

  @override
  void initState() {
    super.initState();
    txt.listen((onData) {
      if (onData != null) {
        setState(() {
          txtController.text = onData;
        });
      }
    });
    widget.simulatorPref?.listen((simulatorPref) {
      if (simulatorPref != null) {
        setState(() {
          this.simulatorPref = simulatorPref;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final routeCreationBloc =
        Provider.of<ManagerBloc>(context).routeCreationBlog;

    if (!simulatorPref) {
      txtController.text = "Mein Standort";
    }
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
                  color: Colors.black45, width: 0.5, style: BorderStyle.solid)),
          child: Row(
            children: <Widget>[
              Expanded(
                child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () async {
                      if (simulatorPref) {
                        final Place place = await showSearch(
                            context: context,
                            delegate: PlaceSearch(),
                            query: txtController.text);
                        widget.onValueChanged(place);
                        WebSocketService.instance.delegate = routeCreationBloc;
                      }
                    },
                    child: TextField(
                      controller: txtController,
                      keyboardType: TextInputType.text,
                      enabled: false,
                      decoration:
                          new InputDecoration.collapsed(hintText: hintText),
                    )),
              ),
              IconButton(
                icon: Icon(Icons.clear),
                color: Colors.black45,
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

class PlaceSearch extends SearchDelegate<Place>
    implements WebSocketServiceDelegate {
  List<Place> places = [];

  PlaceSearch() {
    WebSocketService.instance.delegate = this;
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
      children: <Widget>[],
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    WebSocketService.instance
        .sendCommand(GetLocationFromAddress(Configuration.sessionUUID, query));
    // TODO: implement buildSuggestions
    return ListView(
      children: <Widget>[
        for (var place in places)
          ListTile(
            title: Text(place.displayName),
            subtitle: Text('Lat: ' +
                place.lat.toString() +
                ' Long: ' +
                place.lon.toString()),
            onTap: () {
              close(context, place);
            },
          )
      ],
    );
  }

  @override
  void websocketDidReceiveMessage(String msg) {
    WebsocketResponse response = WebsocketResponse.fromJson(jsonDecode(msg));
    if (response.method == WebSocketMethod.getLocationFromAddress) {
      var response = AddressToLocationResponse.fromJson(jsonDecode(msg));

      this.places = response.places;
    }
  }
}
