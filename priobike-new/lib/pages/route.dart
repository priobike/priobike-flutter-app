import 'package:flutter/material.dart';
import 'package:priobike/utils/routes.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _RoutePageState();
  }
}

class _RoutePageState extends State<RoutePage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PrioBike: RoutePage'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              ElevatedButton(
                child: const Text('Zur Fahransicht'),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Routes.cycling);
                },
              ),
              ElevatedButton(
                child: const Text('Zurück'),
                onPressed: () {
                  Navigator.pop(context);
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
