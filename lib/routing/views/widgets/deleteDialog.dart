import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';

showDeleteDialog(
    BuildContext context, String deleteName, onPressed) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          title: BoldContent(
              text: "Sind sie sich sicher, dass sie alle ihre " +
                  deleteName +
                  " löschen möchten?",
              context: context),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface),
              child: Content(text: 'Abbrechen', context: context),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.red),
              child: Content(
                  text: 'Löschen', context: context, color: Colors.white),
              onPressed: () {
                onPressed();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
}
