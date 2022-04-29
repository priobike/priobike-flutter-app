import 'package:flutter/material.dart';
import 'package:priobike/models/point.dart';
import 'package:priobike/services/app.dart';
import 'package:priobike/utils/routes.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AppService app;

  @override
  Widget build(BuildContext context) {
    app = Provider.of<AppService>(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('PrioBike ${app.isStaging ? 'Dresden' : 'Hamburg'}'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.pushNamed(context, Routes.settings);
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Wählen Sie eine Route aus: ",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: !app.isStaging
                    ? [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.traffic),
                            label: const Text('Teststrecke 1: Ost ➔ West'),
                            onPressed: () {
                              app.initSessionAndUpdateRoute([
                                Point(lat: 53.560863, lon: 9.990909),
                                Point(lat: 53.564378, lon: 9.978001),
                              ]);
                              Navigator.pushNamed(context, Routes.route);
                            },
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.traffic),
                            label: const Text('Teststrecke 2: West ➔ Ost'),
                            onPressed: () {
                              app.initSessionAndUpdateRoute([
                                Point(lat: 53.564378, lon: 9.978001),
                                Point(lat: 53.560863, lon: 9.990909),
                              ]);
                              Navigator.pushNamed(context, Routes.route);
                            },
                          ),
                        ),
                      ]
                    : [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.build),
                            label: const Text('Neue Teststrecke um den POT'),
                            onPressed: () {
                              app.initSessionAndUpdateRoute([
                                Point(lon: 13.72757, lat: 51.03148),
                                Point(lon: 13.728232, lat: 51.031149),
                                Point(lon: 13.72923, lat: 51.03065),
                                Point(lon: 13.728206, lat: 51.030218),
                                Point(lon: 13.727809, lat: 51.030613),
                                Point(lon: 13.727337, lat: 51.031083),
                              ]);
                              Navigator.pushNamed(context, Routes.route);
                            },
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.traffic),
                            label: const Text('Alte Teststrecke vor POT'),
                            onPressed: () {
                              app.initSessionAndUpdateRoute([
                                Point(lon: 13.728029, lat: 51.03063),
                                Point(lon: 13.727347, lat: 51.030582),
                                Point(lon: 13.727347, lat: 51.030353),
                                Point(lon: 13.727791, lat: 51.030343),
                                Point(lon: 13.728152, lat: 51.030576),
                              ]);
                              Navigator.pushNamed(context, Routes.route);
                            },
                          ),
                        ),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
