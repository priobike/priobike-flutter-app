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
                "Filter: Heute, Die Woche, Monat, Alles",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              leading: Icon(Icons.arrow_forward),
              title: Text(
                "Gefahrene Kilometer",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              leading: Icon(Icons.arrow_forward),
              title: Text(
                "Überfahrene Ampeln",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              leading: Icon(Icons.arrow_forward),
              title: Text(
                "Durchschnittsgeschwindigkeit",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
