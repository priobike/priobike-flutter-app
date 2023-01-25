import 'package:flutter/material.dart';

/// A header text.
class Header extends Text {
  Header(
      {Key? key,
      required String text,
      TextOverflow? overflow,
      int? maxLines,
      double? fontSize,
      Color? color,
      required BuildContext context})
      : super(
          text,
          key: key,
          overflow: overflow,
          maxLines: maxLines,
          style: Theme.of(context).textTheme.headline1!.merge(
                TextStyle(color: color, fontSize: fontSize),
              ),
        );
}

/// A sub header text.
class SubHeader extends Text {
  SubHeader(
      {Key? key,
      required String text,
      TextOverflow? overflow,
      int? maxLines,
      Color? color,
      required BuildContext context})
      : super(
          text,
          key: key,
          overflow: overflow,
          maxLines: maxLines,
          style: Theme.of(context).textTheme.subtitle1!.merge(
                TextStyle(color: color),
              ),
        );
}

class BoldSubHeader extends Text {
  BoldSubHeader(
      {Key? key,
      required String text,
      TextOverflow? overflow,
      int? maxLines,
      Color? color,
      TextAlign? textAlign,
      required BuildContext context})
      : super(
          text,
          key: key,
          overflow: overflow,
          maxLines: maxLines,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.subtitle2!.merge(
                TextStyle(color: color),
              ),
        );
}

/// A content text.
class Content extends Text {
  Content(
      {Key? key,
      required String text,
      TextOverflow? overflow,
      int? maxLines,
      Color? color,
      TextAlign? textAlign,
      required BuildContext context})
      : super(
          text,
          key: key,
          overflow: overflow,
          maxLines: maxLines,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.headline2!.merge(
                TextStyle(color: color, fontWeight: FontWeight.normal),
              ),
        );
}

/// A bold content text.
class BoldContent extends Text {
  BoldContent(
      {Key? key,
      required String text,
      TextOverflow? overflow,
      int? maxLines,
      Color? color,
      TextAlign? textAlign,
      required BuildContext context})
      : super(
          text,
          key: key,
          overflow: overflow,
          maxLines: maxLines,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.headline2!.merge(
                TextStyle(color: color),
              ),
        );
}

/// A small text.
class Small extends Text {
  Small(
      {Key? key,
      required String text,
      TextOverflow? overflow,
      int? maxLines,
      Color? color,
      TextAlign? textAlign,
      required BuildContext context})
      : super(
          text,
          key: key,
          overflow: overflow,
          maxLines: maxLines,
          style: Theme.of(context).textTheme.headline3!.merge(
                TextStyle(color: color),
              ),
          textAlign: textAlign,
        );
}

/// A bold small text.
class BoldSmall extends Text {
  BoldSmall(
      {Key? key,
      required String text,
      TextOverflow? overflow,
      int? maxLines,
      Color? color,
      TextAlign? textAlign,
      required BuildContext context})
      : super(
          text,
          key: key,
          overflow: overflow,
          maxLines: maxLines,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.headline4!.merge(
                TextStyle(color: color),
              ),
        );
}
