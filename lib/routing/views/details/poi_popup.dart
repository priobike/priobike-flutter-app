import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/home/services/poi.dart';

class POIInfoPopup extends StatelessWidget {
  final POIElement selectedPOI;

  final Function onPressed;

  const POIInfoPopup({super.key, required this.selectedPOI, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context).size;
    final widgetWidth = frame.width * 0.6;

    return Stack(children: [
      Container(
        // 1 pixel less then the height of the triangle so that the border gets hidden.
        margin: const EdgeInsets.only(top: 15),
        width: widgetWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(width: 1, color: Theme.of(context).colorScheme.onTertiary),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BoldSmall(
              text: selectedPOI.name,
              context: context,
              textAlign: TextAlign.center,
            ),
            const SmallVSpace(),
            IconTextButtonPrimary(
              label: "Als Wegpunkt hinzufügen",
              onPressed: () => onPressed,
              boxConstraints: BoxConstraints(minWidth: frame.width, minHeight: 28.0),
            )
          ],
        ),
      ),
      Positioned(
        // Container width half minus half paint width to center paint.
        left: widgetWidth * 0.5 - 10,
        child: CustomPaint(
          painter: TrianglePainter(
            context: context,
          ),
          child: const SizedBox(
            height: 16,
            width: 20,
          ),
        ),
      ),
    ]);
  }
}

class TrianglePainter extends CustomPainter {
  final BuildContext context;

  TrianglePainter({required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()..color = Theme.of(context).colorScheme.background;

    Paint sidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Theme.of(context).colorScheme.onTertiary
      ..strokeWidth = 1;

    // Draw the background;
    canvas.drawPath(getTrianglePath(size.width, size.height), backgroundPaint);
    // Draw border lines to the top.
    canvas.drawPath(getTrianglePath(size.width, size.height), sidePaint);
  }

  Path getTrianglePath(double x, double y) {
    return Path()
      ..moveTo(0, y)
      ..lineTo(x / 2 - 2, 2)
      ..cubicTo(x / 2 - 2, 2, x / 2, 0, x / 2 + 2, 2)
      ..lineTo(x, y);
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) {
    return false;
  }
}
