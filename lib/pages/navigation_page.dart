import 'package:bikenow/models/vorhersage.dart';
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
    app.vorhersageService.startVorhersage();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    print('render NavigationPage');
    return SafeArea(
      child: Scaffold(
          body: StreamBuilder<List<Vorhersage>>(
        stream: app.vorhersageService.vorhersageStreamController.stream,
        builder:
            (BuildContext context, AsyncSnapshot<List<Vorhersage>> snapshot) {
          return snapshot.data != null
              ? ListView.builder(
                  itemCount: snapshot.data?.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(snapshot.data[index]?.sg),
                      subtitle: Text(snapshot.data[index].isGreen ? "grün": "rot"),//Text(snapshot.data[index]?.timestamp),
                      trailing: CircularProgressIndicator(
                        value: 0.6,
                      ),
                    );
                  },
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Lade Prognosen...'),
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
