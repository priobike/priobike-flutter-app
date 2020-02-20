import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class RouteButton extends StatelessWidget {
  final String title;
  final String start;
  final String destination;
  final Function onPressed;
  final List<Color> colors;

  RouteButton({
    this.title,
    this.start,
    this.destination,
    this.onPressed,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => this.onPressed(),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            gradient: new LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: this.colors,
            ),
            borderRadius: BorderRadius.all(
              Radius.circular(8.0),
            ),
            boxShadow: [
              new BoxShadow(
                color: Colors.grey,
                offset: new Offset(0, 3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  this.title,
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                Spacer(),
                Text(
                  '${this.start} ➜ ${this.destination}',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
