import 'dart:async';

import 'package:bike_now_flutter/Services/router.dart';
import 'package:bike_now_flutter/blocs/bloc_manager.dart';
import 'package:bike_now_flutter/blocs/route_creation_bloc.dart';
import 'package:bike_now_flutter/models/ride.dart';
import 'package:flutter/material.dart';
import 'package:material_segmented_control/material_segmented_control.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MainPageState();
  }
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {

  RouteCreationBloc routeCreationBloc;
  StreamSubscription subscription;


  int _currentSelection = 1;
  bool _isOpen = true;
  set isOpen(bool isOpen) {

    _isOpen = isOpen;

  }
  Map<int, Widget> _children() => {
    0: Text('Heute', style: Theme.of(context).primaryTextTheme.body1,),
    1: Text('7 Tage', style: Theme.of(context).primaryTextTheme.body1),
    2: Text('1 Monat', style: Theme.of(context).primaryTextTheme.body1),
    3: Text('Gesamt', style: Theme.of(context).primaryTextTheme.body1)
  };



  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    routeCreationBloc = Provider.of<ManagerBloc>(context).routeCreationBlog;
    subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            Navigator.pushNamed(context, Router.routeCreationRoute);
          });
        },
        child: Icon(Icons.add, color: Colors.white,),
        backgroundColor: Theme.of(context).primaryColor,
        shape: CircleBorder(side: BorderSide(color: Colors.white, width: 4)),
      ),
      appBar: AppBar(
        title: Text("BikeNow"),
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, Router.settingsRoute);
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onPanStart: (dragDetails){
              setState(() {
                isOpen = !_isOpen;
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15))
                ),

                child: AnimatedSize(
                  vsync: this,
                  curve: Curves.fastOutSlowIn,
                  duration: Duration(milliseconds: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Visibility(
                        visible: _isOpen,
                        maintainAnimation: true,
                        maintainState: true,
                        child: Container(
                          height: 200,
                          color: Theme.of(context).primaryColor,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              MaterialSegmentedControl(
                                children: _children(),
                                selectionIndex: _currentSelection,
                                borderColor: Colors.white,
                                selectedColor: Theme.of(context).primaryColor,
                                unselectedColor: Colors.white12,
                                borderRadius: 5.0,
                                onSegmentChosen: (index) {
                                  setState(() {
                                    _currentSelection = index;
                                  });
                                },
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Expanded(
                                      child: Center(
                                        child: RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            text: '1\n',
                                            style: Theme.of(context).primaryTextTheme.display1,
                                            children: <TextSpan>[
                                              TextSpan(text: 'Fahrten', style: Theme.of(context).primaryTextTheme.overline),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Center(
                                      child: RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          text: '19\n',
                                          style: Theme.of(context).primaryTextTheme.display1,
                                          children: <TextSpan>[
                                            TextSpan(text: 'Ampeln', style: Theme.of(context).primaryTextTheme.overline),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                    Expanded(
                                      child: Center(
                                        child: RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            text: '243 ',
                                            style: Theme.of(context).primaryTextTheme.display1,
                                            children: <TextSpan>[
                                              TextSpan(text: 'g\n', style: Theme.of(context).primaryTextTheme.body1),

                                              TextSpan(text: 'eingespartes CO2', style: Theme.of(context).primaryTextTheme.overline),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Expanded(
                                      child: Center(
                                        child: RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            text: '12 ',
                                            style: Theme.of(context).primaryTextTheme.display1,
                                            children: <TextSpan>[
                                              TextSpan(text: 'km\n', style: Theme.of(context).primaryTextTheme.body1),

                                              TextSpan(text: 'Distanz', style: Theme.of(context).primaryTextTheme.overline),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            text: '34 ',
                                            style: Theme.of(context).primaryTextTheme.display1,
                                            children: <TextSpan>[
                                              TextSpan(text: 'Kcal\n', style: Theme.of(context).primaryTextTheme.body1),
                                              TextSpan(text: 'Energie', style: Theme.of(context).primaryTextTheme.overline),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            text: '0 ',
                                            style: Theme.of(context).primaryTextTheme.display1,
                                            children: <TextSpan>[
                                              TextSpan(text: 'km/h\n', style: Theme.of(context).primaryTextTheme.body1),
                                              TextSpan(text: 'Geschwindigkeit', style: Theme.of(context).primaryTextTheme.overline),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )
                          ,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: Container(
                            height: 2,
                            width: 75,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(Radius.circular(5))
                            ),
                          ),
                        ),
                      )
                    ],

                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: StreamBuilder<List<Ride>>(
                stream: routeCreationBloc.rides,
                initialData: null,
                builder: (context, snapshot) {
                  if (snapshot.data == null || snapshot.data == []) {
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
  }

  Widget _rideTileBuilder(Ride ride, RouteCreationBloc routeCreationBloc) {
    return Dismissible(
      key: Key(UniqueKey().toString()),
      onDismissed: (direction) {
        routeCreationBloc.deleteRides.add(ride.id);
      },
      background: Container(
        color: Colors.red,
        child: Icon(Icons.cancel),
      ),
      child: Card(
        child: ListTile(
          leading: IconButton(
              icon: Icon(ride.isFavorite ? Icons.star : Icons.star_border),
          onPressed: (){
                setState(() {
                  ride.isFavorite = !ride.isFavorite;
                });

          },),
          trailing: Icon(Icons.chevron_right),
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
                        TextSpan(text: ride.start.displayName.substring(0, 20))
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
                      TextSpan(text: ride.end.displayName.substring(0,20))
                    ]),
              )
            ],
          ),

          onTap: () {
            routeCreationBloc.quickTabClicked = true;
            routeCreationBloc.setStart(ride.start);
            routeCreationBloc.setEnd(ride.end);
          },
        ),
      ),
    );
  }

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
}