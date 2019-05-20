import 'package:flutter/material.dart';

class LocationPointWidget extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(
          color: Colors.black26,
          blurRadius: 3.0,
          spreadRadius: 0.1,
        )],
          border: Border.all(
              color: Colors.white,
              width: 1,
              style: BorderStyle.solid
          )
      ),
      padding: EdgeInsets.all(1),
      child: Center(
        child: Icon(
          Icons.directions_bike,
          color: Colors.white,
          size: 12,
        ),
      ),
    );
  }
}