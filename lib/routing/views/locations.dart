import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/profile.dart';
import 'package:priobike/routing/views/widgets/selectOnMap.dart';
import 'package:provider/provider.dart';

class PlacesView extends StatefulWidget {
  const PlacesView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => PlacesViewState();
}

class PlacesViewState extends State<PlacesView> {
  /// The associated shortcuts service, which is injected by the provider.
  Profile? profileService;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    profileService = Provider.of<Profile>(context);

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Hero(
                    tag: 'appBackButton',
                    child: AppBackButton(
                      icon: Icons.chevron_left_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: Center(
                        child: BoldSubHeader(
                          text: "Meine Orte",
                          context: context,
                        ),
                      ),
                    ),
                  ),

                  /// To center the text
                  const SizedBox(width: 80),
                ]),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Row(children: [
                    Expanded(
                      child: BigButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const SelectOnMapView(withName: true)),
                          );
                        },
                        label: 'Ort Hinzufügen',
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
