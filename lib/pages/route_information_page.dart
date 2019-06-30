import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';


import 'package:bike_now/widgets/search_bar_widget.dart';

import 'package:bike_now/widgets/mapbox_widget.dart';
import 'package:bike_now/widgets/route_information_statistic_widget.dart';
import 'package:bike_now/database/database_helper.dart';
import 'package:bike_now/geo_coding/address_to_location_response.dart';



class RouteInformationPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Routeninformation", style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Container(

      ),
    );
  }
}

