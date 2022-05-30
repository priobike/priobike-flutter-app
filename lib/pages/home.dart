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
                        // FIXME: This is all hardcoded and should be loaded dynamically from a json file from assets or HTTP endpoint
                        const Text("Teststrecke 1 (Edmund-Siemers-Allee)"),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.traffic),
                            label: const Text('Ost ➔ West'),
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
                            label: const Text('West ➔ Ost'),
                            onPressed: () {
                              app.initSessionAndUpdateRoute([
                                Point(lat: 53.564378, lon: 9.978001),
                                Point(lat: 53.560863, lon: 9.990909),
                              ]);
                              Navigator.pushNamed(context, Routes.route);
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text("Teststrecke 2 (B4)"),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.traffic),
                            label: const Text('Ost ➔ West'),
                            onPressed: () {
                              app.initSessionAndUpdateRoute([
                                Point(
                                  lat: 53.547722154285324,
                                  lon: 10.004045134575035,
                                ),
                                Point(
                                  lat: 53.549482,
                                  lon: 9.978636,
                                ),
                                Point(
                                  lat: 53.550264133830126,
                                  lon: 9.971739418506827,
                                )
                              ]);
                              Navigator.pushNamed(context, Routes.route);
                            },
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.traffic),
                            label: const Text('West ➔ Ost'),
                            onPressed: () {
                              app.initSessionAndUpdateRoute([
                                Point(
                                  lon: 9.971606990198367,
                                  lat: 53.54990402934412,
                                ),
                                Point(
                                  lon: 10.004240381440082,
                                  lat: 53.547262160720436,
                                ),
                              ]);
                              Navigator.pushNamed(context, Routes.route);
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text("Teststrecke 3 (Lombardsbrücke)"),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.traffic),
                            label: const Text('Ost ➔ West'),
                            onPressed: () {
                              app.initSessionAndUpdateRoute([
                                Point(
                                  lon: 10.0062077,
                                  lat: 53.5511715,
                                ),
                                Point(
                                  lon: 9.99471,
                                  lat: 53.5575131,
                                ),
                                Point(
                                  lon: 9.9828379,
                                  lat: 53.5575762,
                                ),
                                Point(
                                  lon: 9.976352,
                                  lat: 53.55285,
                                ),
                              ]);
                              Navigator.pushNamed(context, Routes.route);
                            },
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.traffic),
                            label: const Text('West ➔ Ost'),
                            onPressed: () {
                              app.initSessionAndUpdateRoute([
                                Point(
                                  lon: 9.976352,
                                  lat: 53.55285,
                                ),
                                Point(
                                  lon: 9.9859757,
                                  lat: 53.5579687,
                                ),
                                Point(
                                  lon: 10.005804047062561,
                                  lat: 53.551241482916915,
                                ),
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
                                Point(lon: 13.730213, lat: 51.030151),
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
