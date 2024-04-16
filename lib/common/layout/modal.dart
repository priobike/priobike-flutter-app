import 'package:flutter/material.dart';

/// Show a modal sheet with a border radius and slightly transparent background.
void showAppSheet({
  required BuildContext context,
  required WidgetBuilder builder,
  isScrollControlled = false,
  showDragHandle = false,
}) {
  showModalBottomSheet(
    context: context,
    showDragHandle: showDragHandle,
    builder: (context) {
      // Clip the content to the rounded corners.
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: builder(context),
      );
    },
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.95),
    isScrollControlled: isScrollControlled,
  );
}
