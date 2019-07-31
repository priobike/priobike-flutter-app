import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bike_now/widgets/search_bar_widget.dart';
import 'package:bike_now/database/database_helper.dart';
import 'package:bike_now/blocs/route_creation_bloc.dart';
import 'package:bike_now/blocs/bloc_manager.dart';

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
  bool isLoading = false;
  bool isOwnLocationSearch = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeCreationBloc = Provider.of<ManagerBloc>(context).routeCreationBlog;
    subscription?.cancel();
    subscription = routeCreationBloc.getState.listen((state) {
      if (state == CreationState.navigateToInformationPage) {
        isLoading = false;
        Navigator.pushNamed(context, '/second');
        routeCreationBloc.setState(CreationState.routeCreation);
      }
    });
  }

  Widget RideLoadingSwitchButton(bool isLoading) {
    if (isLoading) {
      return CircularProgressIndicator();
    } else {
      return IconButton(
        icon: Icon(Icons.directions_bike, color: Colors.blue),
        onPressed: () {
          routeCreationBloc.addRides();
          routeCreationBloc.setState(CreationState.waitingForResponse);
          setState(() {
            isLoading = true;
          });
        },
      );
    }
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
          Center(child: RideLoadingSwitchButton(isLoading)),
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

    // TODO: implement build
    return Scaffold(
        backgroundColor: Colors.white,
        body: StreamBuilder<CreationState>(
            stream: routeCreationBloc.getState,
            initialData: CreationState.routeCreation,
            builder: (context, snapshot) {
              return SafeArea(
                child: body,
              );
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
