import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/profile.dart';

showDeleteDialog(BuildContext context, Profile? profileService, String deleteName) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          title: BoldSubHeader(
              text:
                  "Sind sie sich sicher, dass sie alle ihre " + deleteName + " löschen möchten?",
              context: context),
          actions: <Widget>[
            TextButton(
              child: Content(
                  text: 'Abbrechen',
                  context: context,
                  color: Theme.of(context).colorScheme.primary),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Content(
                  text: 'Löschen',
                  context: context,
                  color: Theme.of(context).colorScheme.primary),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
}
