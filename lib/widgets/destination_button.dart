import 'package:bikenow/config/bikenow_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class DestinationButton extends StatelessWidget {
  final String destination;
  final Function onPressed;

  DestinationButton({
    this.destination,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      color: BikeNowTheme.button,
      elevation: BikeNowTheme.buttonElevation,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${this.destination}',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w100,
                ),
              ),
              Text(
                "4km",
                style: TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.w100,
                ),
              )
            ],
          ),
        ),
      ),
      onPressed: () => this.onPressed(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(12.0),
        ),
      ),
    );
  }
}
