import 'package:bikenow/models/api/api_prediction.dart';
import 'package:bikenow/models/vorhersage.dart';
import 'package:bikenow/services/app_router.dart';
import 'package:bikenow/services/main_service.dart';
import 'package:bikenow/services/vorhersage_service.dart';
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
  Widget build(BuildContext context) {
    app = Provider.of<MainService>(context);
    app.predictionService.subscribeToRoute();
    app.vorhersageService.startVorhersage();
    return SafeArea(
      child: Scaffold(
          body: StreamBuilder<List<Vorhersage>>(
        stream: app.vorhersageService.vorhersageStreamController.stream,
        builder:
            (BuildContext context, AsyncSnapshot<List<Vorhersage>> snapshot) {
          return ListView.builder(
            itemCount: snapshot.data?.length,
            itemBuilder: (context, index) {
              return snapshot.data != null
                  ? ListTile(
                      title: Text(snapshot.data[index]?.sg),
                      subtitle: Text("${snapshot.data[index].countdown}"),
                      trailing: CircularProgressIndicator(
                        value: 0.6,
                      ),
                    )
                  : Text('lase');
            },
          );
        },
      )),
    );
  }

  @override
  void dispose() {
    app.predictionService.unsubscribeFromRoute();
    app.vorhersageService.endVorhersage();
    super.dispose();
  }
}

//  Card(
//               child: ListTile(
//                 title: Text('Fahrt beenden'),
//                 onTap: () {
//                   Navigator.pushReplacementNamed(context, Router.summaryRoute);
//                 },
//               ),
//             ),
