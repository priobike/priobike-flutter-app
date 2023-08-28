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
          style: Theme.of(context).textTheme.displayLarge!.merge(
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
      TextAlign? textAlign,
      required BuildContext context})
      : super(
          text,
          key: key,
          overflow: overflow,
          maxLines: maxLines,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.titleMedium!.merge(
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
          style: Theme.of(context).textTheme.titleSmall!.merge(
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
          style: Theme.of(context).textTheme.displayMedium!.merge(
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
          style: Theme.of(context).textTheme.displayMedium!.merge(
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
          style: Theme.of(context).textTheme.displaySmall!.merge(
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
          style: Theme.of(context).textTheme.headlineMedium!.merge(
                TextStyle(color: color),
              ),
        );
}

/// A text with a shadow behind it.
class ShadowedText extends StatelessWidget {
  /// The text to display.
  final String text;

  /// The font size.
  final double fontSize;

  /// The height of the text.
  final double height;

  /// The text color.
  final Color textColor;

  /// The background color.
  final Color backgroundColor;

  /// The stroke width.
  final double strokeWidth = 3;

  /// The blur radius of the shadow.
  final double blurRadius = 1;

  const ShadowedText({
    Key? key,
    required this.text,
    required this.textColor,
    required this.backgroundColor,
    required this.fontSize,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            height: height,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = strokeWidth
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius)
              ..color = backgroundColor,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            height: height,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
