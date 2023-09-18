import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';

class RewardBadge extends StatelessWidget {
  final Color color;

  final double size;

  final int value;

  const RewardBadge({Key? key, required this.color, required this.size, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: Size.square(size),
      child: Stack(
        children: [
          Icon(
            Icons.shield,
            color: value > 0 ? color : Theme.of(context).colorScheme.onBackground.withOpacity(0.25),
            size: size,
          ),
          if (value > 0)
            Center(
              child: BoldSubHeader(
                text: '$value',
                color: Colors.white,
                height: 1,
                context: context,
              ),
            ),
        ],
      ),
    );
  }
}
