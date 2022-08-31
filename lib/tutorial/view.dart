

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/tutorial/service.dart';
import 'package:provider/provider.dart';

/// A small tutorial view which can be used to show a tutorial.
class TutorialView extends StatefulWidget {
  /// The id of the tutorial.
  final String id;

  /// The text of the tutorial.
  final String text;

  /// The optional padding of the tutorial.
  final EdgeInsetsGeometry? padding;

  const TutorialView({
    required this.id,
    required this.text,
    this.padding,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => TutorialViewState();
}

class TutorialViewState extends State<TutorialView> {
  /// The associated tutorial service, which is injected by the provider.
  late TutorialService tutorialService;

  /// Whether a green checkmark should be shown.
  bool checkmarkIsShown = false;

  /// Whether the tutorial should be shown. Initially, it is not shown.
  bool tutorialIsShown = false;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      tutorialService.loadCompleted();
    });
  }

  @override
  void didChangeDependencies() {
    tutorialService = Provider.of<TutorialService>(context);
    final wasCompleted = tutorialService.isCompleted(widget.id) ?? false;
    if (!wasCompleted) {
      // If the tutorial was not completed, show it.
      setState(() {
        checkmarkIsShown = false;
        tutorialIsShown = true;
      });
    } else if (!checkmarkIsShown && tutorialIsShown) {
      // If the tutorial was just completed, show the checkmark and hide it after a short delay.
      setState(() {
        checkmarkIsShown = true;
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            tutorialIsShown = false;
          });
        }
      });
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      firstChild: Container(),
      secondChild: Padding(
        padding: widget.padding ?? const EdgeInsets.all(0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Small(
              text: widget.text,
              color: Colors.grey,
            )),
            const SmallHSpace(),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              firstChild: const Icon(Icons.check, color: Colors.green),
              secondChild: const Icon(Icons.info, color: Colors.grey),
              crossFadeState: checkmarkIsShown ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            ),
          ],
        ),
      ),
      crossFadeState: tutorialIsShown? CrossFadeState.showSecond : CrossFadeState.showFirst,
    );
  }
}