import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/tutorial/service.dart';

/// A small tutorial view which can be used to show a tutorial.
class TutorialView extends StatefulWidget {
  /// The id of the tutorial.
  final String id;

  /// The text of the tutorial.
  final String text;

  /// The optional padding of the tutorial.
  final EdgeInsetsGeometry? padding;

  /// The color of the tutorial (text and buttons).
  final Color? color;

  const TutorialView({
    required this.id,
    required this.text,
    this.color,
    this.padding,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => TutorialViewState();
}

class TutorialViewState extends State<TutorialView> {
  /// The associated tutorial service, which is injected by the provider.
  late Tutorial tutorial;

  /// Whether a green checkmark should be shown.
  bool _checkmarkIsShown = false;

  /// Whether the tutorial should be shown. Initially, it is not shown.
  bool _tutorialIsShown = false;

  /// The time in milliseconds for a finished tutorial to fade out.
  final _fadeOutDuration = const Duration(milliseconds: 1000);

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    updateTutorialStatus();
    setState(() {});
  }

  /// Updates the tutorial status.
  void updateTutorialStatus() {
    final wasCompleted = tutorial.isCompleted(widget.id);
    final isActive = tutorial.isActive(widget.id);
    // Only show tutorial if is active and was not completed.
    if (wasCompleted != null && isActive != null && !wasCompleted && isActive) {
      // If the tutorial was not completed, show it.
      setState(
        () {
          _checkmarkIsShown = false;
          _tutorialIsShown = true;
        },
      );
    } else if (wasCompleted != null && !_checkmarkIsShown && _tutorialIsShown) {
      // If the tutorial was just completed, show the checkmark and hide it after a short delay.
      setState(
        () {
          _checkmarkIsShown = true;
        },
      );
      Future.delayed(
        _fadeOutDuration ~/ 2,
        () {
          if (mounted) {
            setState(
              () {
                _tutorialIsShown = false;
              },
            );
          }
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback(
      (_) async {
        tutorial.loadCompleted();
        tutorial.loadActivated();
      },
    );

    tutorial = getIt<Tutorial>();
    tutorial.addListener(update);

    updateTutorialStatus();
  }

  @override
  void dispose() {
    tutorial.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: _fadeOutDuration,
      firstCurve: Curves.easeInOutCubic,
      secondCurve: Curves.easeInOutCubic,
      sizeCurve: Curves.easeInOutCubic,
      crossFadeState: _tutorialIsShown ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: Container(),
      secondChild: Padding(
        padding: widget.padding ?? const EdgeInsets.all(0),
        child: AnimatedOpacity(
          // Show checkmark only when tutorial is completed.
          opacity: _checkmarkIsShown ? 0.0 : 1.0,
          duration: _fadeOutDuration,
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
                      context: context,
                      color: widget.color ?? Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: IconButton(
                      icon: _checkmarkIsShown
                          ? Icon(
                              Icons.check,
                              color: widget.color ?? Theme.of(context).colorScheme.onSurface,
                            )
                          : Icon(
                              Icons.close,
                              color: widget.color ?? Theme.of(context).colorScheme.onSurface,
                            ),
                      // The following call will trigger `notifyListeners()`.
                      onPressed: () => tutorial.complete(widget.id),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
