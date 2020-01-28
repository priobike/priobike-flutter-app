import 'package:bikenow/services/main_service.dart';
import 'package:bikenow/services/app_router.dart';
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
        title: Text("BikeNow Dresden"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Router.settingsRoute),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          Card(
            child: ListTile(
              // leading: IconButton(
              //   icon: Icon(Icons.star_border),
              //   onPressed: () {},
              // ),
              trailing: app.loading
                  ? CircularProgressIndicator()
                  : Icon(Icons.chevron_right),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.black),
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Start: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: 'Albertplatz')
                        ],
                      ),
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Ende: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: 'Technische Universität Dresden')
                      ],
                    ),
                  )
                ],
              ),
              onTap: () async {
                await app.routingService.updateRoute(
                    51.030815, 13.726988, 51.068019, 13.753166);
                Navigator.pushNamed(context, Router.routeInfoRoute);
              },
            ),
          ),
          Card(
            child: ListTile(
              // leading: IconButton(
              //   icon: Icon(Icons.star_border),
              //   onPressed: () {},
              // ),
              trailing: app.loading
                  ? CircularProgressIndicator()
                  : Icon(Icons.chevron_right),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.black),
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Start: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: 'Albertplatz')
                        ],
                      ),
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Ende: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: 'Technische Universität Dresden')
                      ],
                    ),
                  )
                ],
              ),
              onTap: () async {
                await app.routingService.updateRoute(
                    51.068019, 13.753166, 51.030815, 13.726988);
                Navigator.pushNamed(context, Router.routeInfoRoute);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            Navigator.pushNamed(context, Router.routeCreationRoute);
          });
        },
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: Theme.of(context).primaryColor,
        shape: CircleBorder(
          side: BorderSide(color: Colors.white, width: 4.0),
        ),
        elevation: 10,
      ),
    );
  }
}
