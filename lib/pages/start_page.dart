import 'package:bikenow/config/router.dart';
import 'package:bikenow/services/status_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StartPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _StartPageState();
  }
}

class _StartPageState extends State<StartPage> {
  @override
  Widget build(BuildContext context) {
    final statusService = Provider.of<StatusService>(context);
    return SafeArea(
      child: Scaffold(
        body: Column(
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
                    ),
                  ),
                  Flexible(
                    child: Text(
                      "Achte immer auf die StVO und fahre nie bei Rot! Die Bedienung des Smartphones ist während der Fahrt nicht erlaubt.",
                      style: TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                "Damit wir dir Geschwindigkeitsempfehlungen live auf dein Handy senden können, benötigen wir regelmäßig deine Position. \nDiese Daten werden anonym bei uns gespeichert und ausgewertet. Mehr Informationen findest du dazu auf unserer Webseite.",
                style: TextStyle(
                  fontSize: 14,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            Spacer(),
            OutlineButton(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: statusService.loading
                    ? CircularProgressIndicator()
                    : Text(
                        "Ich bin einverstanden. Los gehts!",
                      ),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppPage.home);
              },
              borderSide: BorderSide(width: 1),
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
                      fontSize: 12,
                      decoration: TextDecoration.none,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    "www.bikenow-dresden.de",
                    style: TextStyle(
                      fontSize: 12,
                      decoration: TextDecoration.none,
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
