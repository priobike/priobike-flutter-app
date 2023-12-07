import 'package:flutter/material.dart' hide Shortcuts, Feedback;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/tiles.dart';

class ButtonPreView extends StatelessWidget {
  const ButtonPreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Row(children: [SmallIconButtonPrimary(icon: Icons.check, onPressed: () {})]),
          const SmallVSpace(),
          Row(children: [
            SmallIconButtonSecondary(icon: Icons.check, onPressed: () {}),
          ]),
          const SmallVSpace(),
          Row(children: [SmallIconButtonTertiary(icon: Icons.check, onPressed: () {})]),
          const SmallVSpace(),
          Row(children: [
            BigButtonPrimary(
              icon: Icons.check,
              onPressed: () {},
              label: 'Primary',
            ),
          ]),
          const SmallVSpace(),
          Row(children: [
            BigButtonSecondary(
              icon: Icons.check,
              onPressed: () {},
              label: 'Secondary',
            ),
          ]),
          const SmallVSpace(),
          Row(children: [
            BigButtonTertiary(
              icon: Icons.check,
              onPressed: () {},
              label: 'Tertiary',
            )
          ]),
          Row(children: [
            Tile(
              onPressed: () {},
              content: const Text("Primary"),
            )
          ]),
          const SmallVSpace(),
          Row(children: [
            IconTextButtonPrimary(
              onPressed: () {},
              label: 'Primary',
              icon: Icons.check,
            )
          ]),
          const SmallVSpace(),
          Row(children: [
            IconTextButtonSecondary(
              onPressed: () {},
              label: 'Secondary',
              icon: Icons.check,
            )
          ]),
          const SmallVSpace(),
          Row(children: [
            IconTextButtonTertiary(
              onPressed: () {},
              label: 'Tertiary',
              icon: Icons.check,
            )
          ]),
          const SmallVSpace(),
        ],
      ),
    );
  }
}
