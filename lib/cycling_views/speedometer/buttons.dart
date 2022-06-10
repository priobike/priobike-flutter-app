import 'package:flutter/material.dart';
import 'package:priobike/utils/routes.dart';

class CancelButton extends StatelessWidget {
  const CancelButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SizedBox(
        width: 164,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.stop),
          label: const Text('Fahrt Beenden'),
          onPressed: () {
            Navigator.pushReplacementNamed(context, Routes.summary);
          },
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color.fromARGB(255, 236, 240, 241))
              )
            ),
            foregroundColor: MaterialStateProperty.all<Color>(const Color.fromARGB(255, 236, 240, 241)),
            backgroundColor: MaterialStateProperty.all<Color>(const Color.fromARGB(255, 44, 62, 80)),
          )
        ),
      ),
    );
  }
}