import 'package:bikenow/config/router.dart';
import 'package:bikenow/models/recommendation.dart';
import 'package:bikenow/services/main_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NavigationPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NavigationPageState();
  }
}

class _NavigationPageState extends State<NavigationPage> {
  MainService app;

  @override
  void didChangeDependencies() {
    app = Provider.of<MainService>(context);
    app.predictionService.subscribeToRoute();
    app.recommendationService.startRecommendation();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: <Widget>[
            Expanded(
              child: StreamBuilder<Recommendation>(
                stream: app.recommendationService.recommendationStreamController
                    .stream,
                builder: (BuildContext context,
                    AsyncSnapshot<Recommendation> snapshot) {
                  if (snapshot.hasData)
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${snapshot.data.label}',
                          style: TextStyle(fontSize: 30),
                        ),
                        Text(
                          'in ${snapshot.data.distance}m',
                          style: TextStyle(fontSize: 30),
                        ),
                        Text(
                          snapshot.data.isGreen ? "jetzt Grün" : "jetzt Rot",
                          style: TextStyle(fontSize: 30),
                        ),
                        Text(
                          'noch ${snapshot.data.secondsToPhaseChange}s',
                          style: TextStyle(fontSize: 80),
                        ),
                        // Spacer(),
                        // SizedBox(
                        //   child: CircularProgressIndicator(
                        //     value: snapshot.data.secondsToPhaseChange / 70,
                        //     strokeWidth: 50,
                        //     valueColor: snapshot.data.isGreen
                        //         ? new AlwaysStoppedAnimation<Color>(
                        //             Colors.green)
                        //         : new AlwaysStoppedAnimation<Color>(
                        //             Colors.red),
                        //   ),
                        //   height: 150,
                        //   width: 150,
                        // ),
                        // Spacer(),
                        Text(
                          snapshot.data.error != null
                              ? '??'
                              : snapshot.data.speedRecommendation == 0
                                  ? '🚴👍'
                                  : snapshot.data.speedRecommendation > 0
                                      ? '🐇 +${snapshot.data.speedRecommendation} km/h'
                                      : '🐌 ${snapshot.data.speedRecommendation} km/h',
                          style: TextStyle(fontSize: 80),
                        ),
                        Text(
                          snapshot.data.error != null
                              ? '${snapshot.data.error}'
                              : '',
                          style: TextStyle(fontSize: 30),
                        ),
                      ],
                    );
                  else
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: <Widget>[
                          Text('Warte auf Berechnung der Empfehlung...'),
                          Text(
                              'Standort, Route oder Prognose noch nicht vorhanden.'),
                        ],
                      ),
                    );

                  // return snapshot.data != null
                  //     ? ListView.builder(
                  //         itemCount: snapshot.data?.length,
                  //         itemBuilder: (context, index) {
                  //           return ListTile(
                  //             title: Text(
                  //                 "${snapshot.data[index]?.label} (${snapshot.data[index]?.distance}m)"),
                  //             subtitle: Text(snapshot.data[index] != null
                  //                 ? snapshot.data[index].isGreen
                  //                     ? "grün ${snapshot.data[index].secondsToPhaseChange}"
                  //                     : "rot ${snapshot.data[index].secondsToPhaseChange}"
                  //                 : 'lade...'), //Text(snapshot.data[index]?.timestamp),
                  //             trailing: CircularProgressIndicator(
                  //               value:
                  //                   snapshot.data[index].secondsToPhaseChange /
                  //                       100,
                  //               valueColor: snapshot.data[index].isGreen
                  //                   ? new AlwaysStoppedAnimation<Color>(
                  //                       Colors.green)
                  //                   : new AlwaysStoppedAnimation<Color>(
                  //                       Colors.red),
                  //             ),
                  //           );
                  //         },
                  //       )
                  //     : Padding(
                  //         padding: const EdgeInsets.all(16.0),
                  //         child: Text('Lade Prognosen...'),
                  //       );
                },
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Fahrt beenden'),
                onTap: () {
                  Navigator.pushReplacementNamed(context, Page.summary);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    app.predictionService.unsubscribeFromRoute();
    app.recommendationService.endRecommendation();
    app.geolocationService.stopGeolocation();
    super.dispose();
  }
}
