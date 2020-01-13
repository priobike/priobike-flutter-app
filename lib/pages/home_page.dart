import 'package:bike_now_flutter/pages/main_page.dart';
import 'package:bike_now_flutter/pages/map_page.dart';
import 'package:bike_now_flutter/pages/news_page.dart';
import 'package:bike_now_flutter/pages/test_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;
  final List<Widget> _children = [
    NewsPage(),
    MainPage(),
    MapPage(),
    TestPage()
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped, // new
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        // this will be set when a new tab is tapped
        items: [
          BottomNavigationBarItem(
            icon: new Icon(Icons.info),
            title: new Text('Neuigkeiten'),
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.directions_bike),
            title: new Text('Fahren'),
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.map),
            title: new Text('Karte'),
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.send),
            title: new Text('Test'),
          )
        ],
      ),
    );
  }
}
