import 'dart:async';

import 'package:flutter/material.dart';
import 'package:priobike/main.dart';

class Toast with ChangeNotifier {
  /// The current content to display.
  Widget? content;

  /// Show an error message as a toast.
  void showError(String message) => showSuccess(message); // TODO

  /// Show a success message as a toast.
  void showSuccess(String message) => show(
        Container(
          height: 42,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 8),
              Text(
                message,
                // Note: context cannot be used here.
                style: const TextStyle(
                  fontFamily: 'HamburgSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );

  /// Show an arbitrary content as toast message.
  void show(Widget content) {
    this.content = content;
    notifyListeners();
  }
}

class ToastWrapper extends StatelessWidget {
  /// The content to display beneath the toast.
  final Widget child;

  const ToastWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        child, // Should not be rebuilt in the widget tree
        const Material(
          color: Colors.transparent,
          child: Toaster(),
        ),
      ],
    );
  }
}

class Toaster extends StatefulWidget {
  const Toaster({super.key});

  @override
  ToasterState createState() => ToasterState();
}

class ToasterState extends State<Toaster> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<Offset> offsetInAnimation;

  /// The currently running timer until the toast is hidden.
  Timer? timer;

  /// The toast instance.
  late Toast toast;

  @override
  void initState() {
    super.initState();
    toast = getIt<Toast>();
    toast.addListener(show);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    const height = 42;
    final pt = MediaQuery.of(context).padding.top; // Display below safe area
    var offset = 8 / height; // Below safe area + 8 pixels of padding
    if (pt > 0 && height > 0) {
      offset += pt / height;
    }
    offsetInAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset(0, offset),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    controller.dispose();
    toast.removeListener(show);
    super.dispose();
  }

  /// Show the current toast as a widget.
  void show() {
    if (toast.content == null) return;

    timer?.cancel();
    setState(() => {});

    // Only forward the animation if it is not already running.
    if (timer == null && !controller.isAnimating) {
      controller.forward(from: 0);
    }
    timer = Timer(const Duration(seconds: 2), () {
      controller.reverse();
      timer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultContainer = Container(
      height: 42,
      width: 32,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
      ),
    );
    return SlideTransition(
      position: offsetInAnimation,
      child: toast.content ?? defaultContainer,
    );
  }
}
