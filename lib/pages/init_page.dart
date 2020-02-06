import 'package:bikenow/config/router.dart';
import 'package:bikenow/config/palette.dart';
import 'package:bikenow/services/gateway_status_service.dart';
import 'package:bikenow/services/main_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InitPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _InitPageState();
  }
}

class _InitPageState extends State<InitPage> {
  @override
  Widget build(BuildContext context) {
    final gatewayStatusService = Provider.of<GatewayStatusService>(context);
    return Container(
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: [0, 1],
            colors: [Palette.primaryColor, Palette.primaryColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Container(
                color: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.info,
                          color: Colors.white,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          "Achte immer auf die StVO und fahre nie bei Rot! Die Bedienung des Smartphones ist während der Fahrt nicht erlaubt.",
                          style: Theme.of(context).primaryTextTheme.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.all(60.0),
                child: Image.asset("assets/images/bikenow.png"),
              ),
              Spacer(),
              RaisedButton(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: gatewayStatusService.loading
                      ? CircularProgressIndicator(
                          backgroundColor: Colors.white,
                        )
                      : Text(
                          "Los gehts! (Offset: ${gatewayStatusService.timeDifference}s)",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Page.home);
                },
                color: Colors.black12,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(40.0))),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "1.0a",
                      style: Theme.of(context).primaryTextTheme.caption,
                    ),
                    Text("www.bikenow-dresden.de",
                        style: Theme.of(context).primaryTextTheme.caption)
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
