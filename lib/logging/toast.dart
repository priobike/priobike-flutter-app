import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/main.dart';

class Toast with ChangeNotifier {
  /// The current content to display.
  Widget? content;

  /// Show a success message as a toast.
  void showSuccess(String message, {bool important = false}) => showIconMessage(
        const Icon(Icons.check_rounded, color: Colors.white, size: 26),
        message,
        important: important,
      );

  /// Show an error message as a toast.
  void showError(String message, {bool important = false}) => showIconMessage(
        const Icon(Icons.error_rounded, color: Colors.white, size: 26),
        message,
        important: important,
      );

  /// Show a message with a given icon widget as a toast.
  void showIconMessage(Widget icon, String message, {bool important = false}) => show(
        Container(
          height: 64,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          margin: const EdgeInsets.only(top: 2, left: 8, right: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  // Note: context cannot be used here.
                  style: const TextStyle(
                    fontFamily: 'HamburgSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        important: important,
      );

  /// Show an arbitrary content as toast message.
  void show(Widget content, {bool important = false}) {
    this.content = content;
    if (important) {
      HapticFeedback.heavyImpact();
    }
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

class ToasterState extends State<Toaster> with TickerProviderStateMixin {
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
    // Only update the animation if it is not already running.
    if (timer != null) return;

    controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    const height = 64;
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
    toast.removeListener(show);
    controller.dispose();
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
      if (!mounted) return;
      controller.reverse();
      timer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultContainer = Container(
      height: 64,
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
