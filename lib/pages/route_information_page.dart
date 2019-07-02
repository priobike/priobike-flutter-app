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


class RouteInformationPage extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    var routeInformationBloc = Provider.of<ManagerBloc>(context).routeInformationBloc;

    return Scaffold(
      appBar: AppBar(
        title: Text("Routeninformation", style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<BikeRoute.Route>(
        stream: routeInformationBloc.getRoute,
        builder: (context, routeSnapshot) {
          return StreamBuilder<String>(
            stream: routeInformationBloc.getStartLabel,
            builder: (context, startSnapshot) {
              return StreamBuilder<String>(
                stream: routeInformationBloc.getEndLabel,
                builder: (context, endSnapshot) {
                  return Column(
                    children: <Widget>[
                      if(routeSnapshot.data != null) Expanded(child: MapBoxWidget(routeSnapshot.data)),

                      Expanded(child: RouteInformationStatisticWidget(routeSnapshot.data, startSnapshot.data, endSnapshot.data))
                    ],
                  );
                }
              );
            }
          );
        }
      ),
    );
  }
}

