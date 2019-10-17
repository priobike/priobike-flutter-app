import 'package:flutter/material.dart';
import 'package:material_segmented_control/material_segmented_control.dart';

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MainPageState();
  }
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {

  final double openHeigt = 200;
  final double closedHeigt = 10;

  int _currentSelection = 1;
  bool _isOpen = true;
  set isOpen(bool isOpen) {

    _isOpen = isOpen;

  }
  Map<int, Widget> _children() => {
    0: Text('Heute', style: Theme.of(context).primaryTextTheme.body1,),
    1: Text('7 Tage', style: Theme.of(context).primaryTextTheme.body1),
    2: Text('1 Monat', style: Theme.of(context).primaryTextTheme.body1),
    3: Text('Gesamt', style: Theme.of(context).primaryTextTheme.body1)
  };



  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            isOpen = !_isOpen;
          });
        },
        child: Icon(Icons.add, color: Theme.of(context).accentColor,),
        backgroundColor: Theme.of(context).primaryColor,
        shape: CircleBorder(side: BorderSide(color: Theme.of(context).accentColor, width: 4)),
      ),
      appBar: AppBar(
        title: Text("BikeNow"),
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, "/settings");
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onPanStart: (dragDetails){
              setState(() {
                isOpen = !_isOpen;
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15))
                ),

                child: AnimatedSize(
                  vsync: this,
                  curve: Curves.fastOutSlowIn,
                  duration: Duration(milliseconds: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Visibility(
                        visible: _isOpen,
                        maintainAnimation: true,
                        maintainState: true,
                        child: Container(
                          height: 200,
                          color: Theme.of(context).primaryColor,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              MaterialSegmentedControl(
                                children: _children(),
                                selectionIndex: _currentSelection,
                                borderColor: Colors.white,
                                selectedColor: Theme.of(context).primaryColor,
                                unselectedColor: Colors.white12,
                                borderRadius: 5.0,
                                onSegmentChosen: (index) {
                                  setState(() {
                                    _currentSelection = index;
                                  });
                                },
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Expanded(
                                      child: Center(
                                        child: RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            text: '1\n',
                                            style: Theme.of(context).primaryTextTheme.display1,
                                            children: <TextSpan>[
                                              TextSpan(text: 'Fahrten', style: Theme.of(context).primaryTextTheme.overline),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Center(
                                      child: RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          text: '19\n',
                                          style: Theme.of(context).primaryTextTheme.display1,
                                          children: <TextSpan>[
                                            TextSpan(text: 'Ampeln', style: Theme.of(context).primaryTextTheme.overline),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                    Expanded(
                                      child: Center(
                                        child: RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            text: '243 ',
                                            style: Theme.of(context).primaryTextTheme.display1,
                                            children: <TextSpan>[
                                              TextSpan(text: 'g\n', style: Theme.of(context).primaryTextTheme.body1),

                                              TextSpan(text: 'eingespartes CO2', style: Theme.of(context).primaryTextTheme.overline),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Expanded(
                                      child: Center(
                                        child: RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            text: '12 ',
                                            style: Theme.of(context).primaryTextTheme.display1,
                                            children: <TextSpan>[
                                              TextSpan(text: 'km\n', style: Theme.of(context).primaryTextTheme.body1),

                                              TextSpan(text: 'Distanz', style: Theme.of(context).primaryTextTheme.overline),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            text: '34 ',
                                            style: Theme.of(context).primaryTextTheme.display1,
                                            children: <TextSpan>[
                                              TextSpan(text: 'Kcal\n', style: Theme.of(context).primaryTextTheme.body1),
                                              TextSpan(text: 'Energie', style: Theme.of(context).primaryTextTheme.overline),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            text: '0 ',
                                            style: Theme.of(context).primaryTextTheme.display1,
                                            children: <TextSpan>[
                                              TextSpan(text: 'km/h\n', style: Theme.of(context).primaryTextTheme.body1),
                                              TextSpan(text: 'Geschwindigkeit', style: Theme.of(context).primaryTextTheme.overline),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )
                          ,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: Container(
                            height: 2,
                            width: 75,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(Radius.circular(5))
                            ),
                          ),
                        ),
                      )
                    ],

                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: <Widget>[
                  Card(
                    child: ListTile(
                        title: Text(''),
                        trailing: Icon(Icons.chevron_right),
                      leading: Icon(Icons.favorite_border),
                    ),
                  )

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  final locationModal = Stack(
    children: [
      Opacity(
        opacity: 0.1,
        child: ModalBarrier(dismissible: false, color: Colors.black87),
      ),
      Center(
        child: Container(
          child: Container(
            height: 100,
            width: 200,
            alignment: Alignment.center,
            decoration: new BoxDecoration(boxShadow: [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 3.0, // has the effect of softening the shadow
                spreadRadius: 3.0, // has the effect of extending the shadow
                offset: Offset(
                  0.0, // horizontal, move right 10
                  0.0, // vertical, move down 10
                ),
              )
            ],
                color: Colors.white),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Warten auf Position..."),
                )
              ],
            ),
          ),
        ),
      ),
    ],
  );

  final websocketModal = Stack(
    children: [
      Opacity(
        opacity: 0.1,
        child: ModalBarrier(dismissible: false, color: Colors.black87),
      ),
      Center(
        child: Container(
          child: Container(
            height: 100,
            width: 200,
            alignment: Alignment.center,
            decoration: new BoxDecoration(boxShadow: [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 3.0, // has the effect of softening the shadow
                spreadRadius: 3.0, // has the effect of extending the shadow
                offset: Offset(
                  0.0, // horizontal, move right 10
                  0.0, // vertical, move down 10
                ),
              )
            ],
                color: Colors.white),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Warten auf Webserver..."),
                )
              ],
            ),
          ),
        ),
      ),
    ],
  );
}