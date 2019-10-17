import 'package:bike_now_flutter/models/ride.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  Completer<GoogleMapController> _controller = Completer();
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(51.029334, 13.728900),
    zoom: 14.4746,
  );

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
        ],
      ),
    );



    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("Neues Ziel"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, "/settings");
            },
          ),
        ],
      ),
        body: Stack(
          children: <Widget>[
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Column(
                      children: <Widget>[
                        Card(
                          child: SearchBarWidget(
                              'Start...',
                              routeCreationBloc.setStart,
                              routeCreationBloc.getStartLabel,
                              routeCreationBloc.getSimulationPref),
                        ),
                        Card(
                          child: SearchBarWidget(
                              'Ziel...',
                              routeCreationBloc.setEnd,
                              routeCreationBloc.getEndLabel),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                    boxShadow: [new BoxShadow(
                      color: Colors.grey,
                      blurRadius: 2.0,
                    ),]
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Albertplatz --> Hauptbahnhof", style: Theme.of(context).textTheme.title,),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                child: Center(child: Text("0km")),
                              ),
                              Expanded(
                                child: Center(child: Text("0km")),
                              ),
                              Expanded(
                                child: Center(child: Text("0km")),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )

          ],

        )
    );
  }

  @override
  bool get wantKeepAlive => true;
}
