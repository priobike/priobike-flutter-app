import 'package:bike_now_flutter/blocs/bloc_manager.dart';
import 'package:bike_now_flutter/blocs/route_information_bloc.dart';
import 'package:flutter/material.dart';
import 'package:bike_now_flutter/models/route.dart' as BikeRoute;
import 'package:provider/provider.dart';

class RouteInformationStatisticWidget extends StatelessWidget {
  RouteInformationBloc routeInformationBloc;
  Widget _tileBuilder(String value, String unit, String subTitle) {
    return Column(
      children: <Widget>[
        Center(
          child: RichText(
            text: TextSpan(
                style: TextStyle(color: Colors.black),
                children: <TextSpan>[
                  TextSpan(
                      text: value,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
                  TextSpan(text: ' ' + unit)
                ]),
          ),
        ),
        Center(
          child: Text(
            subTitle,
            style: TextStyle(color: Colors.grey),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    routeInformationBloc =
        Provider.of<ManagerBloc>(context).routeInformationBloc;

    return StreamBuilder<BikeRoute.Route>(
        stream: routeInformationBloc.getRoute,
        initialData: null,
        builder: (context, routeSnapshot) {
          if (routeSnapshot.data == null) {
            return Container();
          }
          return StreamBuilder<String>(
              stream: routeInformationBloc.getStartLabel,
              initialData: null,
              builder: (context, startSnapshot) {
                if (startSnapshot.data == null) {
                  return Container();
                }
                return StreamBuilder<String>(
                    stream: routeInformationBloc.getEndLabel,
                    initialData: null,
                    builder: (context, endSnapshot) {
                      if (endSnapshot.data != null) {
                        return Container(
                          padding: EdgeInsets.only(
                              left: 16, top: 16, right: 16, bottom: 8),
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    RichText(
                                      text: TextSpan(
                                          style: TextStyle(color: Colors.black),
                                          children: <TextSpan>[
                                            TextSpan(
                                                text: 'Start: ',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            TextSpan(text: startSnapshot.data)
                                          ]),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                          style: TextStyle(color: Colors.black),
                                          children: <TextSpan>[
                                            TextSpan(
                                                text: 'Ende: ',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            TextSpan(text: endSnapshot.data)
                                          ]),
                                    )
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _tileBuilder(
                                          (routeSnapshot.data.distance / 1000)
                                              .round()
                                              .toString(),
                                          "km",
                                          "Distance"),
                                    ),
                                    Expanded(
                                      child: _tileBuilder(
                                          (routeSnapshot.data.time / 60000)
                                              .round()
                                              .toString(),
                                          "min",
                                          "Dauer"),
                                    ),
                                    Expanded(
                                      child: _tileBuilder(
                                          (routeSnapshot.data.arrivalTime.hour
                                                  .toString() +
                                              ":" +
                                              routeSnapshot
                                                  .data.arrivalTime.minute
                                                  .toString() +
                                              ":" +
                                              routeSnapshot
                                                  .data.arrivalTime.second
                                                  .toString()),
                                          "",
                                          "Ankunftszeit"),
                                    )
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _tileBuilder(
                                          routeSnapshot.data.ascend
                                              .round()
                                              .toString(),
                                          "m",
                                          "Steigung"),
                                    ),
                                    Expanded(
                                      child: _tileBuilder(
                                          routeSnapshot.data.descend
                                              .round()
                                              .toString(),
                                          "m",
                                          "Gefälle"),
                                    ),
                                    Expanded(
                                      child: _tileBuilder(
                                          routeSnapshot.data
                                              .getLSAs()
                                              .length
                                              .toString(),
                                          "x",
                                          "Ampeln"),
                                    )
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: RaisedButton(
                                          onPressed: () {},
                                          child: Text(
                                            'Abbrechen',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: RaisedButton(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                                context, "/navigation");
                                          },
                                          child: Text(
                                            'Starten',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          color: Colors.green,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      } else {
                        return Container();
                      }
                    });
              });
        });
  }
}
