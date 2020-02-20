import 'package:bikenow/config/router.dart';
import 'package:bikenow/services/main_service.dart';
import 'package:bikenow/widgets/route_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MainPageState();
  }
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    final app = Provider.of<MainService>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          app.loading ? "BikeNow Dresden (lade...)" : "BikeNow Dresden",
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Page.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          RouteButton(
            title: 'Pilotstrecke 1',
            start: 'Technische Universität',
            destination: 'Albertplatz',
            colors: [
              Color(0xff4b6cb7),
              Color(0xff182848),
            ],
            onPressed: () async {
              await app.routingService.updateRoute(
                51.030815,
                13.726988,
                51.068019,
                13.753166,
              );
              Navigator.pushNamed(context, Page.routeInfo);
            },
          ),
          RouteButton(
            title: 'Pilotstrecke 1',
            start: 'Albertplatz',
            destination: 'Technische Universität',
            colors: [
              Color(0xff182848),
              Color(0xfff12711),
            ],
            onPressed: () async {
              await app.routingService.updateRoute(
                51.068019,
                13.753166,
                51.030815,
                13.726988,
              );
              Navigator.pushNamed(context, Page.routeInfo);
            },
          ),
        ],
      ),
      //
      //
      //
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.pushNamed(context, Page.routeCreation);
      //   },
      //   child: Icon(
      //     Icons.add,
      //     color: Colors.white,
      //   ),
      //   backgroundColor: Theme.of(context).primaryColor,
      //   shape: CircleBorder(
      //     side: BorderSide(color: Colors.white, width: 4.0),
      //   ),
      //   elevation: 10,
      // ),
      //
      //
      //
    );
  }
}
