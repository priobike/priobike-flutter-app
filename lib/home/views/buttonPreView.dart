import 'package:flutter/material.dart' hide Shortcuts, Feedback;
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';

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
              onPressed: () {},
              label: 'Primary',
            )
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
        ],
      ),
    );
  }
}
