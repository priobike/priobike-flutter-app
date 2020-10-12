import 'package:bikenow/config/bikenow_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class RouteButton extends StatelessWidget {
  final int index;
  final String title;
  final String start;
  final String destination;
  final String description;
  final Function onPressed;
  final List<Color> colors;

  RouteButton({
    this.index,
    this.title,
    this.start,
    this.destination,
    this.onPressed,
    this.colors,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      color: BikeNowTheme.button,
      elevation: BikeNowTheme.buttonElevation,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
            child: Text(
              '${this.index}',
              style: TextStyle(fontSize: 40),
            ),
          ),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${this.start} ⇾ ${this.destination}',
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
        ],
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
