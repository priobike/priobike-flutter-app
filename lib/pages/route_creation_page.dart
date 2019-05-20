import 'package:flutter/material.dart';

import 'package:bike_now/widgets/search_bar_widget.dart';

class RouteCreationPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Route erstellen', style: TextStyle(color: Colors.black),),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Flexible(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SearchBarWidget('Start...'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SearchBarWidget('Ziel...'),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: IconButton(
                    icon: Icon(Icons.swap_vert, size: 30, color: Colors.blue,),
                  ),
                )
              ],
            ),
            Center(child: IconButton(icon: Icon(Icons.directions_bike, color: Colors.blue))),



          ],
        ),
      ),
    );
  }
}