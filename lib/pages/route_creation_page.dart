import 'package:bike_now_flutter/Services/router.dart';
import 'package:bike_now_flutter/blocs/settings_bloc.dart';
import 'package:bike_now_flutter/main.dart';
import 'package:bike_now_flutter/models/models.dart' as BikeNow;
import 'package:bike_now_flutter/widgets/route_information_map.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bike_now_flutter/widgets/search_bar_widget.dart';
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
    with AutomaticKeepAliveClientMixin<RouteCreationPage>, RouteAware {
  RouteCreationBloc routeCreationBloc;
  SettingsBloc settingsBloc;
  StreamSubscription subscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    routeCreationBloc = Provider.of<ManagerBloc>(context).routeCreationBlog;
    routeCreationBloc.onAppear();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));

    // Provide Blocs
    routeCreationBloc = Provider.of<ManagerBloc>(context).routeCreationBlog;
    settingsBloc = Provider.of<SettingsBloc>(context);
    subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Neues Ziel"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.pushNamed(context, Router.settingsRoute);
              },
            ),
          ],
        ),
        body: Stack(
          children: <Widget>[
            RouteInformationMap(),
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
                        StreamBuilder<bool>(
                            stream: settingsBloc.simulator,
                            initialData: false,
                            builder: (context, snapshot) {
                              return Visibility(
                                visible: snapshot.data,
                                child: Card(
                                  child: SearchBarWidget(
                                      'Start...',
                                      routeCreationBloc.setStart,
                                      routeCreationBloc.getStartLabel,
                                      routeCreationBloc.getSimulationPref),
                                ),
                              );
                            }),
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
              child: StreamBuilder<BikeNow.Route>(
                  stream: routeCreationBloc.getRoute,
                  builder: (context, snapshot) {
                    return Visibility(
                      visible: snapshot.data != null ? true : false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          FloatingActionButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, Router.navigationRoute);
                            },
                            child: Icon(
                              Icons.navigation,
                              color: Colors.white,
                            ),
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: CircleBorder(
                                side:
                                    BorderSide(color: Colors.white, width: 4)),
                          ),
                          Container(
                            color: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      topRight: Radius.circular(15)),
                                  boxShadow: [
                                    new BoxShadow(
                                      color: Colors.grey,
                                      blurRadius: 2.0,
                                    ),
                                  ]),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: <Widget>[
                                    StreamBuilder<String>(
                                        stream: routeCreationBloc.getStartLabel,
                                        initialData: "-",
                                        builder: (context, startSnapshot) {
                                          return Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: StreamBuilder<String>(
                                                stream: routeCreationBloc
                                                    .getEndLabel,
                                                initialData: "-",
                                                builder: (context, snapshot) {
                                                  return Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: <Widget>[
                                                      Expanded(
                                                          child: Center(
                                                              child: Text(
                                                                  "${startSnapshot.data.split(',')[0]}",
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .title))),
                                                      Center(
                                                          child: Icon(Icons
                                                              .arrow_forward)),
                                                      Expanded(
                                                          child: Center(
                                                              child: Text(
                                                        "${snapshot.data.split(',')[0]}",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .title,
                                                      ))),
                                                    ],
                                                  );
                                                }),
                                          );
                                        }),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Expanded(
                                            child: Center(
                                                child: Text(
                                              (snapshot.data?.time ?? 0 / 60000)
                                                      .round()
                                                      .toString() +
                                                  " min",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subhead,
                                            )),
                                          ),
                                          Expanded(
                                            child: Center(
                                                child: Text(
                                                    (snapshot.data?.distance ??
                                                                0 / 1000)
                                                            .round()
                                                            .toString() +
                                                        " km",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .subhead)),
                                          ),
                                          Expanded(
                                            child: Center(
                                                child: Text(
                                                    snapshot.data
                                                            ?.getLSAs()
                                                            ?.length
                                                            ?.toString() ??
                                                        "0" + " Ampeln",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .subhead)),
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
            )
          ],
        ));
  }

  @override
  bool get wantKeepAlive => true;
}
