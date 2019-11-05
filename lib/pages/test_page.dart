import 'package:flutter/material.dart';

class TestPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _TestPageState();
  }
}

class _TestPageState extends State<TestPage>{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("MQTT Test"),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () {
          print("Send");
        },
      ),
      body: Column(
        children: <Widget>[
          Text("Eingabe"),
          TextField(),
          Text("Ausgabe"),
          Expanded(
            child: Text(""),
          )
        ],
      ),
    );
  }
}