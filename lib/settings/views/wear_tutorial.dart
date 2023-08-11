import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WearTutorialView extends StatefulWidget {
  const WearTutorialView({Key? key}) : super(key: key);

  @override
  WearTutorialViewState createState() => WearTutorialViewState();
}

class WearTutorialViewState extends State<WearTutorialView> {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Container(),
        ),
      ),
    );
  }
}
