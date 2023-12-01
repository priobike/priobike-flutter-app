import 'package:flutter/material.dart';

/// Displays a loading screen.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var frame = MediaQuery.of(context);

    return Container(
      width: frame.size.width,
      height: frame.size.height,
      color: Colors.black.withOpacity(0.25),
      child: const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
