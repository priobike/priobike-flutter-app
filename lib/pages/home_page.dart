import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_page.dart';
import 'route_creation_page.dart';
import 'package:bike_now_flutter/blocs/settings_bloc.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _children = [RouteCreationPage(), SettingsPage()];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      builder: (context) => SettingsBloc(),
      child: Scaffold(
        body: _children[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          onTap: onTabTapped, // new
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          // this will be set when a new tab is tapped
          items: [
            BottomNavigationBarItem(
              icon: new Icon(Icons.directions_bike),
              title: new Text('Start'),
            ),
            BottomNavigationBarItem(
              icon: new Icon(Icons.settings),
              title: new Text('Einstellungen'),
            ),
          ],
        ),
      ),
    );
  }
}
