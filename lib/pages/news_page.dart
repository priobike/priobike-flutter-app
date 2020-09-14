import 'package:flutter/material.dart';

class NewsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NewsPageState();
  }
}

class _NewsPageState extends State<NewsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black.withOpacity(0),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Neuigkeiten", style: TextStyle(color: Colors.white)),
        ));
  }
}
