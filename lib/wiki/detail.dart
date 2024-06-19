import 'dart:async';

import 'package:flutter/material.dart';
import 'package:priobike/common/layout/annotated_region.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/wiki/models/article.dart';

class WikiDetailView extends StatefulWidget {
  const WikiDetailView({super.key, required this.article});

  /// The article to be displayed.
  final Article article;

  @override
  WikiDetailViewState createState() => WikiDetailViewState();
}

class WikiDetailViewState extends State<WikiDetailView> {
  /// PageController.
  final PageController pageController = PageController();

  /// Initial position of the animated icon.
  final double startPositionRight = 60;

  /// Position of the animated icon.
  double positionRight = 60;

  /// Bool that checks if the page was slid without hint.
  bool didSlidePage = false;

  /// Bool that checks if the page was slid without hint.
  bool showIcon = false;

  /// Timer used for the delay of showAnimation function.
  Timer? showAnimationTimer;

  /// Timer used for the delay of startAnimation function.
  Timer? startAnimationTimer;

  /// Timer used for the delay of startAnimation function.
  Timer? bikeAnimationTimer;

  /// Bike image number for bike animation.
  int bikeImageNumber = 0;

  /// Bike position left used for animation.
  double posLeft = 0;

  /// Int used for the page number.
  int page = 0;

  /// Duration used for the bike and statusBar animation.
  final Duration animationDuration = const Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    _showAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // PreCache images for bike animation.
    for (int i = 0; i <= 8; i++) {
      precacheImage(AssetImage("assets/images/wiki/bike$i.png"), context);
    }
  }

  /// Function that checks if a hint for the page slide is needed and starts the animation if so.
  _showAnimation() {
    showAnimationTimer = Timer(const Duration(seconds: 15), () {
      if (!didSlidePage) {
        setState(() {
          showIcon = true;
        });
        _startAnimation(const Duration(milliseconds: 200));
      }
    });
  }

  /// Function that starts the slide page hint animation.
  _startAnimation(Duration duration) {
    // stops the animation when no icon should be shown.
    if (showIcon) {
      startAnimationTimer = Timer(duration, () {
        setState(() {
          positionRight = 20;
          showIcon = true;
        });
      });
    }
  }

  /// Function that starts the bike animation.
  _startBikeAnimation() {
    if (bikeAnimationTimer != null && bikeAnimationTimer!.isActive) {
      bikeAnimationTimer!.cancel();
    }
    // Timer going through the 9 animations and stopping after.
    bikeAnimationTimer = Timer.periodic(const Duration(milliseconds: 111), (timer) {
      if (bikeImageNumber + 1 == 9) {
        timer.cancel();
      }
      setState(() {
        bikeImageNumber = (bikeImageNumber + 1) % 9;
      });
    });
  }

  /// Widget that displays the text item.
  Widget _pageContent(String text, String? image) {
    return Padding(
      // Padding bottom 20 + AppBackButton height.
      padding: const EdgeInsets.only(left: 24, top: 12, right: 24, bottom: 64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (image != null) ...[
            SizedBox(
              height: 128,
              child: Image.asset(
                image,
                fit: BoxFit.contain,
              ),
            ),
            const VSpace(),
          ],
          Content(
            text: text,
            context: context,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Widget that displays a statusBar item.
  Widget _statusBarItem(int index) {
    return AnimatedContainer(
      width: 24,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        color: index <= page ? Colors.white : Colors.transparent,
      ),
      duration: animationDuration,
    );
  }

  /// Widget that displays the statusBar.
  Widget _statusBar(MediaQueryData frame) {
    List<Widget> statusBarItems =
        widget.article.paragraphs.map((e) => _statusBarItem(widget.article.paragraphs.indexOf(e))).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: statusBarItems,
    );
  }

  @override
  void dispose() {
    super.dispose();

    // Cancel timer.
    showAnimationTimer?.cancel();
    startAnimationTimer?.cancel();
    bikeAnimationTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pageViewItems = [];
    for (int i = 0; i < widget.article.paragraphs.length; i++) {
      final text = widget.article.paragraphs[i];
      final image = widget.article.images.length > i ? widget.article.images[i] : null;
      pageViewItems.add(_pageContent(text, image));
    }

    final frame = MediaQuery.of(context);

    return AnnotatedRegionWrapper(
      bottomBackgroundColor: Theme.of(context).colorScheme.primary,
      colorMode: Theme.of(context).brightness,
      bottomTextBrightness: Brightness.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              color: Theme.of(context).colorScheme.primary,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.only(left: 32, right: 32, bottom: 24),
                  child: _statusBar(frame),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Row(
                      children: [
                        AppBackButton(onPressed: () => Navigator.pop(context)),
                        const HSpace(),
                        Expanded(
                          child: Container(
                            width: frame.size.width,
                            color: Theme.of(context).colorScheme.surface,
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                BoldContent(
                                  text: widget.article.title,
                                  context: context,
                                  textAlign: TextAlign.left,
                                ),
                                Small(
                                  text: widget.article.subtitle,
                                  context: context,
                                  textAlign: TextAlign.left,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const HSpace(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(children: [
                      PageView(
                        children: pageViewItems,
                        onPageChanged: (index) {
                          setState(() {
                            didSlidePage = true;
                            showIcon = false;
                            positionRight = startPositionRight;
                            // ((( screen width - 20 padding) / number of pages ) * index ).
                            posLeft = (((frame.size.width - 100) / (widget.article.paragraphs.length)) * index);
                            page = index;
                          });
                          startAnimationTimer?.cancel();
                          _startBikeAnimation();
                        },
                      ),
                      AnimatedPositioned(
                        bottom: 12,
                        right: positionRight,
                        onEnd: () {
                          setState(() {
                            positionRight = startPositionRight;
                          });
                          _startAnimation(const Duration(milliseconds: 2000));
                        },
                        duration: const Duration(milliseconds: 2000),
                        curve: Curves.easeInOutCubicEmphasized,
                        child: showIcon
                            ? const Opacity(
                                opacity: 0.25,
                                child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 32,
                                ),
                              )
                            : Container(),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
