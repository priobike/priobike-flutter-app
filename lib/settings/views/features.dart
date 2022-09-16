import 'package:flutter/material.dart';
import 'package:priobike/settings/services/features.dart';
import 'package:provider/provider.dart';

class FeatureLoaderView extends StatefulWidget {
  final Widget child;

  const FeatureLoaderView({required this.child, Key? key}) : super(key: key);

  @override 
  FeatureLoaderViewState createState() => FeatureLoaderViewState();
}

class FeatureLoaderViewState extends State<FeatureLoaderView> {
  /// The associated feature service, which is injected by the provider.
  late Feature s;

  @override
  void didChangeDependencies() {
    s = Provider.of<Feature>(context);

    // Load once the window was built.
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await s.load();
    });

    super.didChangeDependencies();
  }

  @override 
  Widget build(BuildContext context) {
    if (!s.hasLoaded) {
      return Scaffold(body: 
        Container(
          color: Theme.of(context).colorScheme.background,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Lade...", style: TextStyle(fontSize: 16)),
            ]
          ),
        ),
      );
    }

    return widget.child;
  }
}
