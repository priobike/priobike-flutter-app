import 'package:bike_now_flutter/blocs/bloc_manager.dart';
import 'package:bike_now_flutter/websocket/web_socket_service.dart';
import 'package:bike_now_flutter/widgets/route_information_map.dart';
import 'package:flutter/material.dart';

import 'package:bike_now_flutter/widgets/route_information_statistic_widget.dart';

import 'package:bike_now_flutter/blocs/route_information_bloc.dart';

import 'dart:async';

import 'package:provider/provider.dart';

class RouteInformationPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RouteInformationPageState();
  }
}

class _RouteInformationPageState extends State<RouteInformationPage> {
  RouteInformationBloc routeInformationBloc;
  StreamSubscription subscription;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Stack(
        children: [
          Column(
            children: <Widget>[
              Expanded(child: RouteInformationMap()),
              Expanded(child: RouteInformationStatisticWidget())
            ],
          ),
          Positioned(
            child: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                  WebSocketService.instance.delegate =
                      Provider.of<ManagerBloc>(context).routeCreationBlog;
                }),
          )
        ],
      ),
    ));
  }
}
