import 'package:flutter/material.dart';

class SummaryPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SummaryPageState();
  }
}

class _SummaryPageState extends State<SummaryPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("Fahrt beendet!"),
      ),
      body: Column(
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 16),
              child: Text("Danke für deine Meldungen!", style: Theme.of(context).textTheme.title,),
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
              child: Text("Wie bewertest du deine Fahrt", style: Theme.of(context).textTheme.title,),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0, bottom: 4),
            child: Card(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Bewertung"),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 4.0, bottom: 8),
              child: Card(
                child: Center(child: Text('Textfeld')),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15))
                      ),
                      child: Text("überspringen"),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15))
                      ),
                      child: Text("Feedback senden"),
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