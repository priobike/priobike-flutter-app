import 'package:flutter/material.dart';
import 'package:priobike/services/app.dart';
import 'package:priobike/utils/routes.dart';
import 'package:provider/provider.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _StartPageState();
  }
}

class _StartPageState extends State<StartPage> {
  late AppService app;

  @override
  Widget build(BuildContext context) {
    app = Provider.of<AppService>(context);
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text("PrioBike: StartPage"),
              Text("clientId:" + app.clientId),
              Text(app.session.sessionId ?? 'warte auf sessionId...'),
              ElevatedButton(
                child: Text(
                    app.session.sessionId != null ? 'Zur HomePage' : 'Lade...'),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Routes.home);
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
