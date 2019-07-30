import 'package:bike_now/blocs/helper/routing_dashboard_info.dart';
import 'package:bike_now/blocs/navigation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:bike_now/models/models.dart' as BikeNow;
import 'package:provider/provider.dart';
import 'package:bike_now/blocs/bloc_manager.dart';

import 'package:bike_now/widgets/mapbox_widget.dart';

import '../main.dart';

class NavigationPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NavigationPageState();
  }
}

class _NavigationPageState extends State<NavigationPage> with RouteAware {
  NavigationBloc navigationBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    super.didPush();
    navigationBloc = Provider.of<ManagerBloc>(context).navigationBloc;
    navigationBloc.startRouting();
  }

  phaseColor(bool isGreen) {
    if (isGreen)
      return Colors.green;
    else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Navigation",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<RoutingDashboardInfo>(
          stream: navigationBloc.getDashboardIngo,
          initialData: null,
          builder: (context, snapshot) {
            if (snapshot.data != null) {
              return Container(
                padding: EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                              child: Icon(
                            Icons.arrow_upward,
                            size: 40,
                          )),
                          Expanded(
                            child: Center(
                              child: Text(
                                snapshot.data.currentInstruction.text,
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: <Widget>[

                                Text("name: " + snapshot.data.nextSG.sgName),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(flex: 3, child: MapBoxWidget()),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          color: Colors.green,
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.all(16),
                              width: 50,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'Empfohlene Anpassung',
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      ((snapshot.data.diffSpeed * 3.6)
                                              .round()
                                              .toString() +
                                          " km/h"),
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ]),
                          ),
                          Expanded(
                              child: Center(
                                  child: Text(
                            ((snapshot.data.currentSpeed * 3.6)
                                    .round()
                                    .toString() +
                                " hm/h"),
                            style: TextStyle(fontSize: 30),
                          )))
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'Ampel Distanz(Meter):',
                                  ),
                                  Text(
                                    (snapshot.data.nextSG.distance * 1000)
                                        .round()
                                        .toString(),
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ]),
                          ),
                          Expanded(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    'Ampelphase:',
                                  ),
                                  Container(
                                      color: phaseColor(
                                          snapshot.data.nextSG.isGreen),
                                      child: Text(snapshot.data.secondsLeft.toString() +
                                          " s",
                                          style: TextStyle(fontSize: 24))),
                                ]),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                        child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: RaisedButton(
                            color: Colors.red,
                            onPressed: () {},
                            child: Text(
                              'Falsche Prognose',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        )),
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: RaisedButton(
                            color: Colors.red,
                            onPressed: () {},
                            child: Text(
                              'Fehlerhafte Fahranweisung',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ))
                      ],
                    ))
                  ],
                ),
              );
            } else {
              return Container();
            }
          }),
    );
  }
}
