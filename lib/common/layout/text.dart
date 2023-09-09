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
      TextAlign? textAlign,
      double? height,
      required BuildContext context})
      : super(
          text,
          key: key,
          overflow: overflow,
          maxLines: maxLines,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.displayLarge!.merge(
                TextStyle(color: color, fontSize: fontSize, height: height),
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
      TextAlign? textAlign,
      double? height,
      required BuildContext context})
      : super(
          text,
          key: key,
          overflow: overflow,
          maxLines: maxLines,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.titleMedium!.merge(
                TextStyle(color: color, height: height),
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
      double? height,
      required BuildContext context})
      : super(
          text,
          key: key,
          overflow: overflow,
          maxLines: maxLines,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.titleSmall!.merge(
                TextStyle(color: color, height: height),
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
      double? height,
      required BuildContext context})
      : super(
          text,
          key: key,
          overflow: overflow,
          maxLines: maxLines,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.displayMedium!.merge(
                TextStyle(color: color, fontWeight: FontWeight.normal, height: height),
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
      double? height,
      required BuildContext context})
      : super(
          text,
          key: key,
          overflow: overflow,
          maxLines: maxLines,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.displayMedium!.merge(
                TextStyle(color: color, height: height),
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
      double? height,
      required BuildContext context})
      : super(
          text,
          key: key,
          overflow: overflow,
          maxLines: maxLines,
          style: Theme.of(context).textTheme.displaySmall!.merge(
                TextStyle(color: color, height: height),
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
      double? height,
      required BuildContext context})
      : super(
          text,
          key: key,
          overflow: overflow,
          maxLines: maxLines,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.headlineMedium!.merge(
                TextStyle(color: color, height: height),
              ),
        );
}
