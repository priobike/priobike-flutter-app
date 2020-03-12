import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class RouteButton extends StatelessWidget {
  final String title;
  final String start;
  final String destination;
  final String description;
  final Function onPressed;
  final List<Color> colors;

  RouteButton({
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
      color: Colors.white,
      child: Container(
        height: 140,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${this.start} ⇾ ${this.destination}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Spacer(),
              Text(
                this.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
              Spacer(),
              Text(
                this.description,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
      onPressed: () => this.onPressed(),
      // borderSide: BorderSide(width: 1, color: Palette.primaryColor),
      splashColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(16.0),
        ),
      ),
    );
  }
}
