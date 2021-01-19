import 'package:flutter/material.dart';

class StatisticsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _StatisticsPageState();
  }
}

class _StatisticsPageState extends State<StatisticsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Text(
              "Todo:",
              style: TextStyle(color: Colors.white),
            ),
            ListTile(
              leading: Icon(Icons.arrow_forward),
              title: Text(
                "Filter: Heute, 7 Tage, 1 Monat, Gesamt",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              leading: Icon(Icons.arrow_forward),
              title: Text(
                "absolvierte Fahrten",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              leading: Icon(Icons.arrow_forward),
              title: Text(
                "gefahrene Distanz",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              leading: Icon(Icons.arrow_forward),
              title: Text(
                "eingespartes CO₂",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              leading: Icon(Icons.arrow_forward),
              title: Text(
                "überfahrene Ampeln",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              leading: Icon(Icons.arrow_forward),
              title: Text(
                "durchschn. Geschwindigkeit",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
