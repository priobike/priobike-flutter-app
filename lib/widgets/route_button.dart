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
      color: Color(0xff424242),
      elevation: 1,
      child: Container(
        height: 120,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                '${this.start} ⇾ ${this.destination}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.start,
              ),
              Spacer(),
              Text(
                this.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Spacer(),
              Text(
                this.description,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
      onPressed: () => this.onPressed(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(2.0),
        ),
      ),
    );
  }
}
