import 'package:priobike/config/priobike_theme.dart';
import 'package:priobike/config/router.dart';
import 'package:priobike/services/status_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        backgroundColor: PrioBikeTheme.background,
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: <Widget>[
              Spacer(flex: 2),
              Container(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PrioBike-HH",
                      style: GoogleFonts.inter(
                        fontSize: 50,
                        fontWeight: FontWeight.w500,
                        color: PrioBikeTheme.text,
                      ),
                    ),
                    Text(
                      "GLOSA App",
                      style: GoogleFonts.inter(
                          fontSize: 28, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Spacer(flex: 2),
              Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
                    child: Icon(
                      Icons.traffic,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      "Damit wir dir Geschwindigkeitsempfehlungen live auf dein Handy senden können, benötigen wir deine Position in Echtzeit.",
                      style: TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.none,
                        color: PrioBikeTheme.text,
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(),
              Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
                    child: Icon(
                      Icons.location_on,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      "Diese Daten werden anonym bei uns gespeichert und ausgewertet. Mehr Informationen findest du dazu auf unserer Webseite.",
                      style: TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.none,
                        color: PrioBikeTheme.text,
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(),
              Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
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
                        fontWeight: FontWeight.w600,
                        color: PrioBikeTheme.text,
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(flex: 2),
              RaisedButton(
                color: PrioBikeTheme.button,
                elevation: PrioBikeTheme.buttonElevation,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    width: double.infinity,
                    child: statusService.loading
                        ? CircularProgressIndicator()
                        : Center(
                            child: Text(
                              "Ich bin einverstanden. Los gehts!",
                              style: TextStyle(
                                color: PrioBikeTheme.text,
                                fontWeight: FontWeight.w100,
                              ),
                            ),
                          ),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppPage.home);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(12.0),
                  ),
                ),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "v0.1.0",
                  style: TextStyle(
                    fontSize: 12,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.w400,
                    color: Colors.white60,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
