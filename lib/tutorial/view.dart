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
  late Tutorial tutorial;

  /// Whether a green checkmark should be shown.
  bool checkmarkIsShown = false;

  /// Whether the tutorial should be shown. Initially, it is not shown.
  bool tutorialIsShown = false;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      tutorial.loadCompleted();
    });
  }

  @override
  void didChangeDependencies() {
    tutorial = Provider.of<Tutorial>(context);
    final wasCompleted = tutorial.isCompleted(widget.id);
    if (wasCompleted != null && !wasCompleted) {
      // If the tutorial was not completed, show it.
      setState(() {
        checkmarkIsShown = false;
        tutorialIsShown = true;
      });
    } else if (wasCompleted != null && !checkmarkIsShown && tutorialIsShown) {
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
    if (!tutorialIsShown) {
      return Container();
    }
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      firstChild: Container(),
      secondChild: Padding(
        padding: widget.padding ?? const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: BoldSmall(text: widget.text, color: const Color.fromARGB(255, 91, 91, 91), context: context),
                ),
                const SmallHSpace(),
                Column(children: [
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    firstChild: const Icon(Icons.check, color: Colors.green),
                    secondChild: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.tips_and_updates, color: Color.fromARGB(255, 91, 91, 91))),
                    crossFadeState: checkmarkIsShown ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  ),
                  const SmallVSpace(),
                  Small(text: "Tutorial", color: const Color.fromARGB(255, 91, 91, 91), context: context),
                ]),
              ],
            ),
          ],
        ),
      ),
      crossFadeState: tutorialIsShown ? CrossFadeState.showSecond : CrossFadeState.showFirst,
    );
  }
}
