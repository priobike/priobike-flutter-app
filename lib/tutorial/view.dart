import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  /// The time in milliseconds for a finished tutorial to fade out.
  final int _fadeOutDuration = 1000;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback(
      (_) async {
        tutorial.loadCompleted();
      },
    );
  }

  @override
  void didChangeDependencies() {
    tutorial = Provider.of<Tutorial>(context);
    final wasCompleted = tutorial.isCompleted(widget.id);
    if (wasCompleted != null && !wasCompleted) {
      // If the tutorial was not completed, show it.
      setState(
        () {
          checkmarkIsShown = false;
          tutorialIsShown = true;
        },
      );
    } else if (wasCompleted != null && !checkmarkIsShown && tutorialIsShown) {
      // If the tutorial was just completed, show the checkmark and hide it after a short delay.
      setState(
        () {
          checkmarkIsShown = true;
        },
      );
      Future.delayed(
        Duration(milliseconds: _fadeOutDuration),
        () {
          if (mounted) {
            setState(
              () {
                tutorialIsShown = false;
              },
            );
          }
        },
      );
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (!tutorialIsShown) {
      return Container();
    }
    return Padding(
      padding: widget.padding ?? const EdgeInsets.all(0),
      child: AnimatedOpacity(
        /// If the checkmark is not show (i.e. the tutorial wasn't yet completet), the opacity is 1, otherwise it is 0.
        opacity: !checkmarkIsShown ? 1.0 : 0.0,
        duration: Duration(milliseconds: _fadeOutDuration),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: BoldSmall(
                      text: widget.text,
                      color: const Color.fromARGB(255, 91, 91, 91),
                      context: context),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: IconButton(
                    icon: checkmarkIsShown
                        ? const Icon(
                            Icons.check,
                            color: Color.fromARGB(255, 91, 91, 91),
                          )
                        : const Icon(
                            Icons.close,
                            color: Color.fromARGB(255, 91, 91, 91),
                          ),
                    onPressed: () {
                      // will trigger didChangeDependencies()
                      tutorial.complete(widget.id);
                    },
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
