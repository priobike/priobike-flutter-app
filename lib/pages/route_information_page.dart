import 'package:bike_now/blocs/route_creation_bloc.dart';
import 'package:bike_now/widgets/route_information_map.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import 'package:bike_now/widgets/search_bar_widget.dart';

import 'package:bike_now/widgets/mapbox_widget.dart';
import 'package:bike_now/widgets/route_information_statistic_widget.dart';
import 'package:bike_now/database/database_helper.dart';
import 'package:bike_now/geo_coding/address_to_location_response.dart';
import 'package:bike_now/blocs/route_information_bloc.dart';
import 'package:bike_now/models/route.dart' as BikeRoute;
import 'package:bike_now/blocs/bloc_manager.dart';

import 'dart:async';

class RouteInformationPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
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
            children: [Column(
              children: <Widget>[
                Expanded(child: RouteInformationMap()),
                Expanded(child: RouteInformationStatisticWidget())
              ],
            ), Positioned(
              child: IconButton(icon: Icon(Icons.arrow_back), onPressed: (){Navigator.pop(context);}),
            )],
          ),
        ));
  }
}
