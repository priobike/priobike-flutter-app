import 'package:flutter/material.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';

/// A list item with icon.
class IconItem extends Row {
  IconItem({super.key, required IconData icon, required String text, required BuildContext context})
      : super(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Icon(
                icon,
                color: CI.radkulturRed,
                size: 64,
                semanticLabel: text,
              ),
            ),
            const SmallHSpace(),
            Expanded(
              child: Content(text: text, context: context),
            ),
          ],
        );
}
