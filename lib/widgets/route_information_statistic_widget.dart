import 'package:flutter/material.dart';
import 'package:bike_now/database/database_helper.dart';
import 'package:bike_now/models/route.dart' as BikeRoute;

class RouteInformationStatisticWidget extends StatelessWidget {
  final BikeRoute.Route route;
  final String start;
  final String end;

  const RouteInformationStatisticWidget(this.route,this.start, this.end);

  Widget _tileBuilder(String value, String unit, String subTitle){
    return Column(
      children: <Widget>[
        Center(
          child: RichText(
            text: TextSpan(
                style: TextStyle(color: Colors.black),
                children: <TextSpan> [
                  TextSpan(text: value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
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
                        TextSpan(text: start.substring(0, 30))
                      ]
                  ),
                ),
                RichText(
                  text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: <TextSpan> [
                        TextSpan(text: 'Ende: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: end.substring(0, 30))
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
                  child: _tileBuilder((route.distance/1000).round().toString(), "km", "Distance"),
                ),
                Expanded(
                  child: _tileBuilder((route.time/60000).round().toString(), "min", "Dauer"),
                ),
                Expanded(
                  child: _tileBuilder((route.arrivalTime.hour.toString() + ":" + route.arrivalTime.minute.toString() + ":" + route.arrivalTime.second.toString()), "", "Ankunftszeit"),
                )
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _tileBuilder(route.ascend.round().toString(), "m", "Steigung"),
                ),
                Expanded(
                  child: _tileBuilder(route.descend.round().toString(), "m", "Gefälle"),
                ),
                Expanded(
                  child: _tileBuilder(route.getLSAs().length.toString(), "x", "Ampeln"),
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