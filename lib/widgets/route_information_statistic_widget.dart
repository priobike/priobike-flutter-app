import 'package:flutter/material.dart';
import 'package:bike_now/database/database_helper.dart';

class RouteInformationStatisticWidget extends StatelessWidget {
  final Ride ride;

  const RouteInformationStatisticWidget(this.ride);

  Widget _tileBuilder(double value, String unit, String subTitle){
    return Column(
      children: <Widget>[
        Center(
          child: RichText(
            text: TextSpan(
                style: TextStyle(color: Colors.black),
                children: <TextSpan> [
                  TextSpan(text: (value).toInt().toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
                  TextSpan(text: ' ' + unit)
                ]
            ),
          ),
        ),
        Center(
          child: Text(
              subTitle,
          style: TextStyle(color: Colors.grey),),
        )

      ],
    );

  }

  @override
  Widget build(BuildContext context) {

    // TODO: implement build
    return Container(
      padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 8),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                RichText(
                  text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: <TextSpan> [
                        TextSpan(text: 'Start: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: ride.start.displayName)
                      ]
                  ),
                ),
                RichText(
                  text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: <TextSpan> [
                        TextSpan(text: 'Ende: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: ride.end.displayName)
                      ]
                  ),
                )

              ],
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _tileBuilder(773, "m", "Distance"),
                ),
                Expanded(
                  child: _tileBuilder(3, "min", "Dauer"),
                ),
                Expanded(
                  child: _tileBuilder(932, "", "Ankunftszeit"),
                )
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _tileBuilder(7, "m", "Steigung"),
                ),
                Expanded(
                  child: _tileBuilder(8, "m", "Gefälle"),
                ),
                Expanded(
                  child: _tileBuilder(0, "x", "Ampeln"),
                )
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(onPressed: () {}, child: Text('Abbrechen', style: TextStyle(color: Colors.white),), color: Colors.red,),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(onPressed: () {
                      Navigator.pushNamed(context, '/navigation');

                    }, child: Text('Starten', style: TextStyle(color: Colors.white),), color: Colors.green,),
                  ),
                )
              ],
            ),
          )
        ],

      ),
    );
  }

}