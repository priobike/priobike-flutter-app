import 'package:bike_now_flutter/blocs/bloc_manager.dart';
import 'package:bike_now_flutter/blocs/test_bloc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TestPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _TestPageState();
  }
}

class _TestPageState extends State<TestPage>{

  TestBloc testBloc;


  @override
  void didChangeDependencies() {
    testBloc = Provider.of<ManagerBloc>(context).testBloc;

    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("MQTT Test"),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () {
          print("Send");
        },
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Ausgabe", style: Theme.of(context).textTheme.headline,),
          ),
          Expanded(
            child: StreamBuilder(
              stream: testBloc.getMessage,
              initialData: "",
              builder: (context, snapshot) {
                return Text(snapshot.data);
              },
            ),
          )
        ],
      ),
    );
  }
}