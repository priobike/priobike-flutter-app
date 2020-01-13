import 'package:bike_now_flutter/Services/router.dart';
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
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text("Neuigkeiten"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, Router.settingsRoute);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("BikeNow die Revolution beginnt"),
                subtitle: Text(
                    "Es ist soweit, BikeNow ist offiziell im PlayStore und dem AppStore erhältlich!"),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Offizielle Ankündigung"),
                subtitle: Text(
                    "Es ist soweit, BikeNow ist offiziell im PlayStore und dem AppStore erhältlich!"),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("BikeNow die Revolution beginnt"),
                subtitle: Text(
                    "Es ist soweit, BikeNow ist offiziell im PlayStore und dem AppStore erhältlich!"),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Offizielle Ankündigung"),
                subtitle: Text(
                    "Es ist soweit, BikeNow ist offiziell im PlayStore und dem AppStore erhältlich!"),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("BikeNow die Revolution beginnt"),
                subtitle: Text(
                    "Es ist soweit, BikeNow ist offiziell im PlayStore und dem AppStore erhältlich!"),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Offizielle Ankündigung"),
                subtitle: Text(
                    "Es ist soweit, BikeNow ist offiziell im PlayStore und dem AppStore erhältlich!"),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("BikeNow die Revolution beginnt"),
                subtitle: Text(
                    "Es ist soweit, BikeNow ist offiziell im PlayStore und dem AppStore erhältlich!"),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Offizielle Ankündigung"),
                subtitle: Text(
                    "Es ist soweit, BikeNow ist offiziell im PlayStore und dem AppStore erhältlich!"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
