import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bike_now/widgets/search_bar_widget.dart';
import 'package:bike_now/database/database_helper.dart';
import 'package:bike_now/blocs/route_creation_bloc.dart';
import 'package:bike_now/geo_coding/address_to_location_response.dart';

class RouteCreationPage extends StatelessWidget {
  BuildContext _context;
  RouteCreationBloc routeCreationBloc;

  RouteCreationPage(){

  }


  @override
  Widget build(BuildContext context) {
    routeCreationBloc = Provider.of<RouteCreationBloc>(context);
    _context = context;


    Widget body = Container(
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Flexible(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SearchBarWidget(
                          'Start...', routeCreationBloc.setStart, routeCreationBloc.getStartLabel),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SearchBarWidget(
                          'Ziel...', routeCreationBloc.setEnd, routeCreationBloc.getEndLabel),
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
          Center(
              child: IconButton(
                icon: Icon(Icons.directions_bike, color: Colors.blue),
                onPressed: () {
                  routeCreationBloc.addRides();
                  routeCreationBloc.setState(
                      CreationState.waitingForResponse);
                  //Navigator.pushNamed(context, '/second');
                },)),
          Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: Colors.grey,
                        width: 1
                    )
                )
            ),
            child: Text('Letzte Fahrten',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),

          ),
          Expanded(
            child: StreamBuilder<List<Ride>>(
              stream: routeCreationBloc.rides,
              initialData: [],
              builder: (context, snapshot) {
                return ListView(
                    children: [
                      for (var ride in snapshot.data)
                        _rideTileBuilder(ride, routeCreationBloc)
                    ]
                );
              },
            ),
          ),

        ],
      ),
    );

    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Route erstellen',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: new Builder(
          builder: (BuildContext context) {
            _context = context;
            routeCreationBloc.serverResponse.listen(_showToast);
            return StreamBuilder<CreationState>(
                stream: routeCreationBloc.getState,
                initialData: CreationState.routeCreation,
                builder: (context, snapshot) {
                  switch(snapshot.data){

                    case CreationState.waitingForResponse:
                      return Container();
                      break;
                    case CreationState.routeCreation:
                      return body;
                      break;
                    case CreationState.navigateToInformationPage:
                      Navigator.pushNamed(context, '/second');

                      break;
                  }
                }

            );
          }
      ),
    );
  }


  void _showToast(String msg) {
    final scaffold = Scaffold.of(_context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(msg),
        action: SnackBarAction(
            label: 'UNDO', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
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
                  children: <TextSpan> [
                    TextSpan(text: 'Start: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ride.start.displayName)
                  ]
                ),
              ),
            ),
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black),
                  children: <TextSpan> [
                    TextSpan(text: 'Ende: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ride.end.displayName)
                  ]
              ),
            )
          ],
        ),
        subtitle: Align(
          alignment: Alignment.bottomRight,
            child: Text(DateTime.fromMillisecondsSinceEpoch(ride.date).day.toString() + '.' + DateTime.fromMillisecondsSinceEpoch(ride.date).month.toString() + '.' + DateTime.fromMillisecondsSinceEpoch(ride.date).year.toString())),

      onTap: () {
          routeCreationBloc.setStart(ride.start);
          routeCreationBloc.setEnd(ride.end);
      },),
    );
  }
}
