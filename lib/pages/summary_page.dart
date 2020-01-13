import 'package:bike_now_flutter/Services/router.dart';
import 'package:bike_now_flutter/helper/palette.dart';
import 'package:flutter/material.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

class SummaryPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SummaryPageState();
  }
}

class _SummaryPageState extends State<SummaryPage> {
  double rating = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Fahrt beendet!"),
      ),
      body: Column(
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 16),
              child: Text(
                "Danke für deine Meldungen!",
                style: Theme.of(context).textTheme.title,
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              direction: Axis.vertical,
              runSpacing: 10,
              children: <Widget>[
                Chip(
                  label: Text("3 falsche Prognosen"),
                  backgroundColor: Colors.white,
                ),
                Chip(
                  label: Text("9 LSA"),
                  backgroundColor: Colors.white,
                ),
                Chip(
                  label: Text("3 falsche Prognosen"),
                  backgroundColor: Colors.white,
                ),
                Chip(
                  label: Text("9 LSA"),
                  backgroundColor: Colors.white,
                ),
                Chip(
                  label: Text("3 falsche Prognosen"),
                  backgroundColor: Colors.white,
                ),
                Chip(
                  label: Text("9 LSA"),
                  backgroundColor: Colors.white,
                ),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Wie bewertest du deine Fahrt?",
                style: Theme.of(context).textTheme.title,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: 8.0, right: 8.0, top: 8.0, bottom: 4),
            child: Card(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SmoothStarRating(
                      allowHalfRating: false,
                      onRatingChanged: (v) {
                        rating = v;
                        setState(() {});
                      },
                      starCount: 5,
                      rating: rating,
                      size: 40.0,
                      color: Theme.of(context).primaryColor,
                      borderColor: Theme.of(context).primaryColor,
                      spacing: 0.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 8.0, right: 8.0, top: 4.0, bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Hier kannst du dein Feedback eingeben'),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15))),
                      onPressed: () {},
                      child: Text(
                        'überspringen',
                        style: TextStyle(color: Palette.primaryColor),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(
                      color: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15))),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                            context, Router.homeRoute, (_) => false);
                      },
                      child: Text(
                        'Feedback senden',
                        style: Theme.of(context).primaryTextTheme.body1,
                      ),
                    ),
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
