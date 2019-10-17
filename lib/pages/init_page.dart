import 'package:bike_now_flutter/helper/palette.dart';
import 'package:flutter/material.dart';

class InitPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _InitPageState();
  }
}

class _InitPageState extends State<InitPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      color: Colors.white,
      child: Container(
        // Add box decoration
        decoration: BoxDecoration(
          // Box decoration takes a gradient
          gradient: LinearGradient(
            // Where the linear gradient begins and ends
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            // Add one stop for each color. Stops should increase from 0 to 1
            stops: [0.1, 0.5, 0.7, 0.9],
            colors: [
              // Colors are easy thanks to Flutter's Colors class.
              Palette.primaryColor.withOpacity(1),
              Palette.primaryColor.withOpacity(0.95),
              Palette.primaryColor.withOpacity(0.9),
              Palette.primaryColor.withOpacity(0.85),

            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Container(

                color: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(Icons.info, color: Colors.white,),
                      ),
                      Flexible(child: Text("Achte immer auf die StVO und fahre nie bei Rot! Die Bedienung des Smartphones ist während der Fahrt nicht erlaubt.", style: Theme.of(context).primaryTextTheme.caption,)),
                    ],
                  ),
                ),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset("assets/images/ic_bikenow.png"),
              ),
              Spacer(),
              RaisedButton(
                child: Text("Los gehts", style: TextStyle(color: Colors.white),),
                onPressed: () {

                  Navigator.pushNamedAndRemoveUntil(context, '/',  (_) => false);

                },
                color: Colors.blueAccent,


              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("1.06", style: Theme.of(context).primaryTextTheme.caption,),
                    Text("www.bikenow-dresden.de", style: Theme.of(context).primaryTextTheme.caption)
                  ],

                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}