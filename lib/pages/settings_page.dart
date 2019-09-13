import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bike_now_flutter/widgets/settings_section_header.dart';
import 'package:bike_now_flutter/blocs/settings_bloc.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SettingsPageState();
  }
}

class SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settingsBloc = Provider.of<SettingsBloc>(context);
    return Scaffold(
        body: ListView(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 32.0, bottom: 32, left: 8),
          child: Text(
            "Einstellungen",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
          ),
        ),
//        SettingsSectionHeader('Allgemeines'),
//        StreamBuilder<int>(
//            stream: settingsBloc.maxSpeed,
//            initialData: 25,
//            builder: (context, snapshot) {
//              return ListTile(
//                title: Text('Maximalgeschwindigkeit'),
//                subtitle: Text(
//                    'Stelle deine Maximalgeschwindigkeit ein. Default ${snapshot.data} km/h'),
//              );
//            }),
//        StreamBuilder<bool>(
//            stream: settingsBloc.racer,
//            initialData: false,
//            builder: (context, snapshot) {
//              return SwitchListTile(
//                title: Text('Rennrad Routing'),
//                subtitle: Text(
//                    'Wenn an, wird für Rennrad geroutet. Neustart erforderlich!'),
//                value: snapshot.data,
//                onChanged: (bool newValue) =>
//                    settingsBloc.setRacer.add(newValue),
//              );
//            }),
//        ListTile(
//          title: Text('Datenschutz'),
//          subtitle: Text(
//              'Klicken Sie hier um mehr über unsere Datenschutzbestimmungen zu erfahren'),
//        ),
//        SettingsSectionHeader('Funktionen'),
//        StreamBuilder<bool>(
//          stream: settingsBloc.dynamicLocation,
//          initialData: false,
//          builder: (context, snapshot) {
//            return SwitchListTile(
//                title: Text('Dynamischer Standort'),
//                subtitle: Text(
//                    '"Spart Energie - Verändert das Intervall der GPS-Abfrage in Abhängigkeit der Entfernung zur nächsten Ampel. Aus = 1s.'),
//                value: snapshot.data,
//                onChanged: (bool newValue) =>
//                    settingsBloc.setDynamicLocation.add(newValue));
//          },
//        ),
//        StreamBuilder<bool>(
//          stream: settingsBloc.optimiyeSystemTime,
//          initialData: false,
//          builder: (context, snapshot) {
//            return SwitchListTile(
//                title: Text('Systemzeit mit GPS optimieren'),
//                subtitle: Text(
//                    "Optimiert deine Systemzeit mithilfe von deinem GPS Signal."),
//                value: snapshot.data,
//                onChanged: (bool newValue) =>
//                    settingsBloc.setOptimiyeSystemTime.add(newValue));
//          },
//        ),
//        StreamBuilder<bool>(
//          stream: settingsBloc.slowlyHideTrafficLightPhase,
//          initialData: false,
//          builder: (context, snapshot) {
//            return SwitchListTile(
//                title: Text('Ampelphase langsam Ausblenden'),
//                subtitle: Text(
//                    "Lässt die Hintergrundfarbe der aktuellen Ampelphase langsam ausblenden."),
//                value: snapshot.data,
//                onChanged: (bool newValue) =>
//                    settingsBloc.setSlowlyHideTrafficLightPhase.add(newValue));
//          },
//        ),
//        StreamBuilder<bool>(
//          stream: settingsBloc.showGPSAccuracy,
//          initialData: false,
//          builder: (context, snapshot) {
//            return SwitchListTile(
//                title: Text('GPS Genauigkeit anzeigen'),
//                subtitle:
//                    Text("Zeigt dir die Genauigkeit deiner GPS Daten an."),
//                value: snapshot.data,
//                onChanged: (bool newValue) =>
//                    settingsBloc.setShowGPSAccuracy.add(newValue));
//          },
//        ),
//        SettingsSectionHeader('Entwickleroptionen'),
//        StreamBuilder<bool>(
//          stream: settingsBloc.debugMode,
//          initialData: false,
//          builder: (context, snapshot) {
//            return SwitchListTile(
//                title: Text('Debug Modus'),
//                subtitle: Text(
//                    "Zeigt Debug-Informationen an und sendet diese an den Server."),
//                value: snapshot.data,
//                onChanged: (bool newValue) =>
//                    settingsBloc.setDebugMode.add(newValue));
//          },
//        ),
//        SettingsSectionHeader('Achtung bei diesen Optionen'),
//        StreamBuilder<int>(
//          stream: settingsBloc.maxAccuracy,
//          initialData: 20,
//          builder: (context, snapshot) {
//            return ListTile(
//              title: Text('Max Accuracy'),
//              subtitle: Text(
//                  "Alle Werte hierüber werden von der QE nicht verwendet. Default: 20 (Meter)"),
//            );
//          },
//        ),
//        StreamBuilder<int>(
//          stream: settingsBloc.minDistance,
//          initialData: 125,
//          builder: (context, snapshot) {
//            return ListTile(
//              title: Text('Min Distance'),
//              subtitle: Text(
//                  "Alle Distanzen höher werden von der QE nicht verarbeitet. Default: 125 (Meter)"),
//            );
//          },
//        ),
//        StreamBuilder<int>(
//          stream: settingsBloc.crossQuantity,
//          initialData: 2,
//          builder: (context, snapshot) {
//            return ListTile(
//              title: Text('Cross Quantity'),
//              subtitle: Text(
//                  "Wenn die QE x mal triggert, gilt sie als überquert. Default: 2 (Anzahl)"),
//            );
//          },
//        ),
//        StreamBuilder<int>(
//          stream: settingsBloc.accuracyModifier,
//          initialData: 80,
//          builder: (context, snapshot) {
//            return ListTile(
//              title: Text('Accuracy Modifier '),
//              subtitle: Text(
//                  "Um die QE zu verbessern, wird die Accuracy des aktuellen Standortes und des letzten Standortes zusätzlich verwendet. Ist der aktuelle Standort nicht weit genug vom letzten entfernt, wird dieser von der QE verworfen.Mit dieser Option lässt sich der Accuracywert des Algorithmus prozentual verkleinern/vergrößern.Default: 80 (Prozent)"),
//            );
//          },
//        ),
        SettingsSectionHeader('Simulator Einstellungen'),
//        StreamBuilder<String>(
//          stream: settingsBloc.password,
//          initialData: "",
//          builder: (context, snapshot) {
//            return ListTile(
//              title: Text('Passwort'),
//              subtitle: Text(
//                  "Setze das richtige Passwort für die nachstehenden Funktionen. Wird für den Emulator- und Simulatorbetrieb verwendet und ist Voraussetzung für die Funktionen dieser Gruppe."),
//            );
//          },
//        ),
//        StreamBuilder<bool>(
//          stream: settingsBloc.pushLocations,
//          initialData: false,
//          builder: (context, snapshot) {
//            return SwitchListTile(
//                title: Text('Push Locations'),
//                subtitle: Text(
//                    "Schickt Positionsdaten an den Server.\nFunktioniert nur mit korrektem Passwort."),
//                value: snapshot.data,
//                onChanged: (bool newValue) =>
//                    settingsBloc.setPushLocations.add(newValue));
//          },
//        ),
        StreamBuilder<bool>(
          stream: settingsBloc.simulator,
          initialData: false,
          builder: (context, snapshot) {
            return SwitchListTile(
                title: Text('Simulator'),
                subtitle: Text(
                    "Startet den Simulatormodus, die App muss danach neu gestartet werden."),
                value: snapshot.data,
                onChanged: (bool newValue) =>
                    settingsBloc.setSimulator.add(newValue));
          },
        )
      ],
    ));
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
