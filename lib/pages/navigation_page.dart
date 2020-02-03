import 'package:bikenow/config/routes.dart';
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
        body: Column(
          children: <Widget>[
            Expanded(
              child: StreamBuilder<List<Vorhersage>>(
                stream: app.vorhersageService.vorhersageStreamController.stream,
                builder: (BuildContext context,
                    AsyncSnapshot<List<Vorhersage>> snapshot) {
                  return snapshot.data != null
                      ? ListView.builder(
                          itemCount: snapshot.data?.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                  "${snapshot.data[index]?.label} (${snapshot.data[index]?.distance}m)"),
                              subtitle: Text(snapshot.data[index] != null
                                  ? snapshot.data[index].isGreen
                                      ? 'grün'
                                      : 'rot'
                                  : 'lade...'), //Text(snapshot.data[index]?.timestamp),
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
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Fahrt beenden'),
                onTap: () {
                  Navigator.pushReplacementNamed(context, Routes.summary);
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
    app.vorhersageService.endVorhersage();
    super.dispose();
  }
}
