import 'package:bikenow/config/router.dart';
import 'package:bikenow/config/palette.dart';
import 'package:bikenow/services/status_service.dart';
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
    final statusService = Provider.of<StatusService>(context);
    return SafeArea(
      child: Container(
        color: Palette.white,
        child: Column(
          children: <Widget>[
            Spacer(),
            Container(
              padding: EdgeInsets.fromLTRB(32, 0, 32, 0),
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 32, 0),
                    child: Icon(
                      Icons.warning,
                      color: Palette.primaryColor,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      "Achte immer auf die StVO und fahre nie bei Rot! Die Bedienung des Smartphones ist während der Fahrt nicht erlaubt.",
                      style: TextStyle(
                          color: Palette.primaryColor,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                          fontFamily: 'Roboto'),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
              ),
            ),
            Image.asset("assets/images/undraw_biking.png"),
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                "Damit wir dir Geschwindigkeitsempfehlungen live auf dein Handy senden können, benötigen wir regelmäßig deine Position. \nDiese Daten werden anonym bei uns gespeichert und ausgewertet. Mehr Informationen findest du dazu auf unserer Webseite.",
                style: TextStyle(
                  color: Palette.primaryColor,
                  fontSize: 14,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            Spacer(),
            OutlineButton(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: statusService.loading
                    ? CircularProgressIndicator(
                        backgroundColor: Palette.primaryColor,
                      )
                    : Text(
                        "Ich bin einverstanden. Los gehts!",
                        style: TextStyle(color: Palette.primaryColor),
                      ),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppPage.home);
              },
              borderSide: BorderSide(width: 1, color: Palette.primaryColor),
              splashColor: Colors.black26,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16.0))),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "v0.1.0",
                    style: TextStyle(
                      color: Palette.primaryColor,
                      fontSize: 12,
                      decoration: TextDecoration.none,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    "www.bikenow-dresden.de",
                    style: TextStyle(
                      color: Palette.primaryColor,
                      fontSize: 12,
                      decoration: TextDecoration.none,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
