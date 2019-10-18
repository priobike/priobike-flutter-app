import 'package:bike_now_flutter/Services/router.dart';
import 'package:bike_now_flutter/blocs/helper/routing_dashboard_info.dart';
import 'package:bike_now_flutter/blocs/navigation_bloc.dart';
import 'package:bike_now_flutter/helper/palette.dart';
import 'package:bike_now_flutter/widgets/speed_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bike_now_flutter/blocs/bloc_manager.dart';

import 'package:bike_now_flutter/widgets/mapbox_widget.dart';

import '../main.dart';

class NavigationPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NavigationPageState();
  }
}

class _NavigationPageState extends State<NavigationPage> with RouteAware {
  NavigationBloc navigationBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));

  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    super.didPush();
    navigationBloc = Provider.of<ManagerBloc>(context).navigationBloc;
    navigationBloc.startRouting();

  }

  @override
  void didPop(){
    super.didPop();
    navigationBloc.didPop();
  }

  phaseColor(bool isGreen) {
    if (isGreen)
      return Colors.green;
    else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SafeArea(
        child: Stack(
          children: [
            MapBoxWidget(),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                child: StreamBuilder<RoutingDashboardInfo>(
                  stream: navigationBloc.getDashboardInfo,
                  builder: (context, snapshot) {
                    if(snapshot.data != null){
                    return Container(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                            color: Palette.primaryDarkBackground,
                            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                            boxShadow: [new BoxShadow(
                              color: Colors.grey,
                              blurRadius: 2.0,
                            ),]
                        ),
                        height: 100,
                        child: Row(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Icon(Icons.arrow_upward, color: Colors.white,),
                            ),
                            Expanded(
                              child: Center(child: Text(snapshot.data.currentInstruction.info, style: Theme.of(context).primaryTextTheme.body1,)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: phaseColor(
                                            snapshot.data.nextSG.isGreen)),
                                    child: Center(
                                      child: Text(
                                          snapshot.data.secondsLeft.toString() +
                                              " s",
                                          style: Theme.of(context).primaryTextTheme.body1),
                                    )),
                              ),
                            )

                          ],

                        ),
                      ),
                    );}else{
                      return Container();
                    }
                  }
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
                child: StreamBuilder<RoutingDashboardInfo>(
                  stream: navigationBloc.getDashboardInfo,
                  builder: (context, snapshot) {
                    if(snapshot.data != null){
                    return Container(
                      color: Colors.transparent,
                      child: Container(
                        height: 250,
                        decoration: BoxDecoration(
                            color: Theme.of(context).backgroundColor,
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                            boxShadow: [new BoxShadow(
                              color: Colors.grey,
                              blurRadius: 2.0,
                            ),]
                        ),
                        child: Column(
                          children: <Widget>[
                            SpeedSlider(snapshot.data.diffSpeed*3.6),
                            Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      ((snapshot.data.diffSpeed * 3.6)
                                          .round()
                                          .toString() +
                                          " km/h"),
                                      style: Theme.of(context).primaryTextTheme.display1,
                                    ),
                                  ),
                                ])
                            ,
                            Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: RaisedButton(
                                            color: Colors.red,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(15))
                                            ),
                                            onPressed: () {
                                              Navigator.pushNamedAndRemoveUntil(context, Router.summaryRoute,  (_) => false);

                                            },
                                            child: Text(
                                              'Falsche Prognose (Fahrt beenden)',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        )),
                                    Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: RaisedButton(
                                            color: Colors.red,
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(15))
                                            ),
                                            onPressed: () {},
                                            child: Text(
                                              'Fehlerhafte Fahranweisung',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ))
                                  ],
                                )),
                            Container(
                              color: Colors.transparent,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Palette.primaryDarkBackground,
                                    borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),

                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            ((snapshot.data.currentSpeed * 3.6)
                                                .round()
                                                .toString() +
                                                " km/h"),
                                            style: Theme.of(context).primaryTextTheme.body1,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            ((snapshot.data.currentSpeed * 3.6)
                                                .round()
                                                .toString() +
                                                " km/h"),
                                            style: Theme.of(context).primaryTextTheme.body1,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            ((snapshot.data.currentSpeed * 3.6)
                                                .round()
                                                .toString() +
                                                " km/h"),
                                            style: Theme.of(context).primaryTextTheme.body1,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            )




                          ],
                        ),
                      ),
                    );}
                    else{
                      return Container();
                    }
                  }
                ),


            ),
            
          ],
        ),
      ),
    );
  }
}
