

import 'package:flutter/material.dart';
import 'package:priobike/common/fx.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';

class AssetTextView extends StatelessWidget {
  /// The asset path for the text that will be displayed.
  final String asset;

  const AssetTextView({required this.asset, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: FutureBuilder(
      future: DefaultAssetBundle.of(context).loadString(asset),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: Stack(
            alignment: Alignment.bottomCenter, 
            children: [
              HPad(
                child: Fade(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        const SizedBox(height: 256),
                        Content(text: snapshot.data ?? "Lade Text...", context: context),
                        const SizedBox(height: 256),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(child: Column(children: [
                const SizedBox(height: 8),
                Row(children: [
                  AppBackButton(onPressed: () => Navigator.pop(context)),
                ]),
              ])),
            ],
          ),
        );
      },
    ));
  }
}