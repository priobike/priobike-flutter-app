import 'package:bike_now_flutter/models/ride.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bike_now_flutter/widgets/search_bar_widget.dart';
import 'package:bike_now_flutter/database/database_helper.dart';
import 'package:bike_now_flutter/blocs/route_creation_bloc.dart';
import 'package:bike_now_flutter/blocs/bloc_manager.dart';

import 'dart:async';

class RouteCreationPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RouteCreationPage();
  }
}

class _RouteCreationPage extends State<RouteCreationPage>
    with AutomaticKeepAliveClientMixin<RouteCreationPage> {
  RouteCreationBloc routeCreationBloc;
  StreamSubscription subscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provide Blocs
    routeCreationBloc = Provider.of<ManagerBloc>(context).routeCreationBlog;
    subscription?.cancel();
    subscription = routeCreationBloc.getState.listen((state){
      if(state == CreationState.navigateToInformationPage){
        Navigator.pushNamed(context, "/routeInfo");
        routeCreationBloc.setState(CreationState.routeCreation);
      }

    });

  }

  Widget SubmitRideButton() {
    return IconButton(
      icon: Icon(Icons.directions_bike, color: Colors.blue),
      onPressed: () {
        routeCreationBloc.addRides();
        routeCreationBloc.setState(CreationState.waitingForWebsocketResponse);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body = Container(
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 32.0, bottom: 32, left: 8),
            child: Text(
              "Route erstellen",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Flexible(
                child: Column(
                  children: <Widget>[
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SearchBarWidget(
                            'Start...',
                            routeCreationBloc.setStart,
                            routeCreationBloc.getStartLabel,
                            routeCreationBloc.getSimulationPref)),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SearchBarWidget(
                          'Ziel...',
                          routeCreationBloc.setEnd,
                          routeCreationBloc.getEndLabel),
                    ),
                  ],
                ),
              ),
              Center(
                child: IconButton(
                  icon: Icon(
                    Icons.swap_vert,
                    size: 30,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    routeCreationBloc.toggleLocations();
                  },
                ),
              )
            ],
          ),
          Center(child: SubmitRideButton()),
          Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Colors.grey, width: 0.5))),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: StreamBuilder<List<Ride>>(
                stream: routeCreationBloc.rides,
                initialData: null,
                builder: (context, snapshot) {
                  if (snapshot.data == null) {
                    return Center(
                        child: Container(child: CircularProgressIndicator()));
                  } else {
                    return ListView(children: [
                      for (var ride in snapshot.data)
                        _rideTileBuilder(ride, routeCreationBloc)
                    ]);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );

    final locationModal = Stack(
      children: [
        Opacity(
          opacity: 0.1,
          child: ModalBarrier(dismissible: false, color: Colors.black87),
        ),
        Center(
          child: Container(
            child: Container(
              height: 100,
              width: 200,
              alignment: Alignment.center,
              decoration: new BoxDecoration(boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  blurRadius: 3.0, // has the effect of softening the shadow
                  spreadRadius: 3.0, // has the effect of extending the shadow
                  offset: Offset(
                    0.0, // horizontal, move right 10
                    0.0, // vertical, move down 10
                  ),
                )
              ],
              color: Colors.white),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Warten auf Position..."),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );

    final websocketModal = Stack(
      children: [
        Opacity(
          opacity: 0.1,
          child: ModalBarrier(dismissible: false, color: Colors.black87),
        ),
        Center(
          child: Container(
            child: Container(
              height: 100,
              width: 200,
              alignment: Alignment.center,
              decoration: new BoxDecoration(boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  blurRadius: 3.0, // has the effect of softening the shadow
                  spreadRadius: 3.0, // has the effect of extending the shadow
                  offset: Offset(
                    0.0, // horizontal, move right 10
                    0.0, // vertical, move down 10
                  ),
                )
              ],
                  color: Colors.white),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Warten auf Webserver..."),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );

    // TODO: implement build
    return Scaffold(
        backgroundColor: Colors.white,
        body: StreamBuilder<CreationState>(
            stream: routeCreationBloc.getState,
            initialData: CreationState.routeCreation,
            builder: (context, snapshot) {
              List<Widget> widgetList = List<Widget>();
              switch (snapshot.data) {
                case CreationState.waitingForLocation:
                  widgetList.add(body);
                  widgetList.add(locationModal);
                  break;
                case CreationState.waitingForWebsocketResponse:
                  widgetList.add(body);
                  widgetList.add(websocketModal);
                  break;
                case CreationState.routeCreation:
                  widgetList.add(body);
                  break;
                case CreationState.navigateToInformationPage:
                  widgetList.add(body);
                  break;
                case CreationState.navigateToNavigationPage:
                  widgetList.add(body);
                  break;
              }
              return SafeArea(child: Stack(children: widgetList));
            }));
  }

  Widget _rideTileBuilder(Ride ride, RouteCreationBloc routeCreationBloc) {
    return Dismissible(
      key: Key(ride.id.toString()),
      onDismissed: (direction) {
        routeCreationBloc.deleteRides.add(ride.id);
      },
      background: Container(
        color: Colors.red,
        child: Icon(Icons.cancel),
      ),
      child: ListTile(
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
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ride.start.displayName)
                    ]),
              ),
            ),
            RichText(
              text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: <TextSpan>[
                    TextSpan(
                        text: 'Ende: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ride.end.displayName)
                  ]),
            )
          ],
        ),
        subtitle: Align(
            alignment: Alignment.bottomRight,
            child: Text(
                DateTime.fromMillisecondsSinceEpoch(ride.date).day.toString() +
                    '.' +
                    DateTime.fromMillisecondsSinceEpoch(ride.date)
                        .month
                        .toString() +
                    '.' +
                    DateTime.fromMillisecondsSinceEpoch(ride.date)
                        .year
                        .toString())),
        onTap: () {
          routeCreationBloc.setStart(ride.start);

          routeCreationBloc.setEnd(ride.end);
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
