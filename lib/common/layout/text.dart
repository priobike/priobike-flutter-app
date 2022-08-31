import 'package:flutter/material.dart';

/// A header text.
class Header extends Text {
  Header({
    Key? key, 
    required String text, 
    TextOverflow? overflow,
    int? maxLines, 
    double fontSize = 38,
    Color color = Colors.black
  }) : super(
    text, 
    key: key, 
    overflow: overflow,
    maxLines: maxLines,
    style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: color),
  );
}

/// A sub header text.
class SubHeader extends Text {
  SubHeader({
    Key? key, 
    required String text, 
    TextOverflow? overflow,
    int? maxLines,
    Color color = Colors.black
  }) : super(
    text, 
    key: key, 
    overflow: overflow,
    maxLines: maxLines,
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, color: color)
  );
}

class BoldSubHeader extends Text {
  BoldSubHeader({
    Key? key, 
    required String text, 
    TextOverflow? overflow,
    int? maxLines,
    Color color = Colors.black
  }) : super(
    text, 
    key: key, 
    overflow: overflow,
    maxLines: maxLines,
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color)
  );
}

/// A content text.
class Content extends Text {
  Content({
    Key? key, 
    required String text, 
    TextOverflow? overflow,
    int? maxLines, 
    Color color = Colors.black
  }) : super(
    text, 
    key: key, 
    overflow: overflow,
    maxLines: maxLines,
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: color)
  );
}

/// A bold content text.
class BoldContent extends Text {
  BoldContent({
    Key? key, 
    required String text, 
    TextOverflow? overflow,
    int? maxLines, 
    Color color = Colors.black
  }) : super(
    text, 
    key: key, 
    overflow: overflow,
    maxLines: maxLines,
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)
  );
}

/// A small text.
class Small extends Text {
  Small({
    Key? key, 
    required String text, 
    TextOverflow? overflow,
    int? maxLines, 
    Color color = Colors.black
  }) : super(
    text, 
    key: key, 
    overflow: overflow,
    maxLines: maxLines,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: color)
  );
}

/// A bold small text.
class BoldSmall extends Text {
  BoldSmall({
    Key? key, 
    required String text, 
    TextOverflow? overflow,
    int? maxLines, 
    Color color = Colors.black
  }) : super(
    text, 
    key: key, 
    overflow: overflow,
    maxLines: maxLines,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)
  );
}