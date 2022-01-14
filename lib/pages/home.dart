import 'package:flutter/material.dart';
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
          title: const Text('PrioBike'),
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
            children: [
              const Text(
                "Wählen Sie eine Route aus: ",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.traffic),
                label: const Text('Teststrecke 1: Ost ➔ West'),
                onPressed: () {
                  app.updateRoute(53.560863, 9.990909, 53.564378, 9.978001);
                  Navigator.pushNamed(context, Routes.route);
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.traffic),
                label: const Text('Teststrecke 2: West ➔ Ost'),
                onPressed: () {
                  app.updateRoute(53.56415, 9.977496, 53.560791, 9.990059);
                  Navigator.pushNamed(context, Routes.route);
                },
              ),
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        ),
      ),
    );
  }
}
