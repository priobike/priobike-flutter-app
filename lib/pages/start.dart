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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              const Text(
                "PrioBike",
                style: TextStyle(fontSize: 60),
              ),
              const Text(
                "Alpha",
                style: TextStyle(fontSize: 20),
              ),
              const Spacer(),
              const SizedBox(
                height: 20,
              ),
              Text(
                "Session ID (${app.isStaging ? 'Stagingsystem' : 'Produktivsystem'}):",
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                app.session.sessionId != null
                    ? "${app.session.sessionId}"
                    : 'Warte auf Session ID...',
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              RadioListTile(
                title: const Text('Produktivsystem (UDP Hamburg)'),
                value: false,
                groupValue: app.isStaging,
                onChanged: (value) {
                  app.setIsStaging(value);
                },
              ),
              RadioListTile(
                title: const Text('Stagingsystem (Testaufbau Dresden)'),
                value: true,
                groupValue: app.isStaging,
                onChanged: (value) {
                  app.setIsStaging(value);
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text(app.session.sessionId != null
                      ? 'Los geht\'s!'
                      : 'Verbinde...'),
                  onPressed: app.session.sessionId != null
                      ? () {
                          Navigator.pushReplacementNamed(context, Routes.home);
                        }
                      : null,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
