import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bike_now/pages/route_information_page.dart';

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

  _SearchBarState(this.hintText);

  @override
  Widget build(BuildContext context) {
    var txt = new TextEditingController();

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
                child: TextField(
                    controller: txt,
                    decoration: new InputDecoration.collapsed(
                        hintText: hintText),
                    onTap: () async {
                      final Place place = await showSearch(
                          context: context,
                          delegate: PlaceSearch(),
                          query: txt.text);
                      setState(() {
                        txt.text = place.displayName;
                      });
                    }),
              ),
              IconButton(
                icon: Icon(Icons.keyboard_voice),
                onPressed: () {},
              )
            ],
          ),
        ));
  }
}
