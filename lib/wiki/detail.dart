import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/wiki/models/article.dart';

class WikiDetailView extends StatefulWidget {
  const WikiDetailView({Key? key, required this.article}) : super(key: key);

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
  Widget _textItem(String text) {
    return Padding(
      // Padding bottom 20 + AppBackButton height.
      padding: const EdgeInsets.only(left: 25, top: 20, right: 25, bottom: 20),
      child: Center(
        child: SubHeader(
          text: text,
          context: context,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Widget that displays a statusBar item.
  Widget _statusBarItem(int index) {
    return Expanded(
      child: AnimatedContainer(
        height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          color: index <= page
              ? Theme.of(context).brightness == Brightness.light
                  ? Colors.black
                  : Colors.white
              : Colors.transparent,
        ),
        duration: animationDuration,
      ),
    );
  }

  /// Widget that displays the statusBar.
  Widget _statusBar(MediaQueryData frame) {
    List<Widget> statusBarItems =
        widget.article.paragraphs.map((e) => _statusBarItem(widget.article.paragraphs.indexOf(e))).toList();

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              AnimatedPositioned(
                left: posLeft,
                bottom: -8,
                duration: animationDuration,
                curve: Curves.easeInOutCubic,
                child: Image(
                  height: 54,
                  width: 54,
                  color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                  image: AssetImage(
                    "assets/images/wiki/bike$bikeImageNumber.png",
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 10,
          width: frame.size.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: statusBarItems,
          ),
        )
      ],
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
    List<Widget> pageViewItems = widget.article.paragraphs.map((text) => _textItem(text)).toList();

    final frame = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Stack(children: [
          Container(
            // Top bar + padding.
            height: frame.padding.top + 8,
            width: frame.size.width,
            color: Theme.of(context).colorScheme.background,
          ),
          Positioned(
            bottom: 0,
            child: Container(
              // Bottom bar.
              height: frame.padding.bottom,
              width: frame.size.width,
              color: Theme.of(context).colorScheme.background,
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Container(
                  color: Theme.of(context).colorScheme.background,
                  child: Row(
                    children: [
                      AppBackButton(onPressed: () => Navigator.pop(context)),
                      Expanded(
                        child: Container(
                          width: frame.size.width,
                          color: Theme.of(context).colorScheme.background,
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
                      const SmallHSpace(),
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
                      bottom: 50,
                      right: positionRight,
                      onEnd: () {
                        setState(() {
                          positionRight = startPositionRight;
                        });
                        _startAnimation(const Duration(milliseconds: 500));
                      },
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      child: showIcon
                          ? const Icon(
                              Icons.arrow_forward,
                              size: 64,
                            )
                          : Container(),
                    ),
                  ]),
                ),
                Container(
                  height: 64,
                  width: frame.size.width,
                  color: Theme.of(context).colorScheme.background,
                  padding: const EdgeInsets.only(left: 50, right: 50, bottom: 10, top: 0),
                  child: _statusBar(frame),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}