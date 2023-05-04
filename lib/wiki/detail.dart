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

  @override
  void initState() {
    super.initState();
    _showAnimation();
  }

  /// Functions that checks if a hint for the page slide is needed.
  _showAnimation() {
    showAnimationTimer = Timer(const Duration(milliseconds: 3000), () {
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

  /// Widget that displays the text.
  Widget _textItem(String text) {
    return Padding(
      // Padding bottom 20 + AppBackButton height.
      padding: const EdgeInsets.only(left: 25, top: 20, right: 25, bottom: 20 + 64),
      child: Center(
        child: SubHeader(
          text: text,
          context: context,
        ),
      ),
    );
  }

  /// Widget that displays the title.
  Widget _titleItem(String title, String subTitle) {
    return Padding(
      // Padding bottom 20 + AppBackButton height.
      padding: const EdgeInsets.only(left: 25, top: 20, right: 25, bottom: 20 + 64),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Header(
              text: title,
              context: context,
            ),
          ),
          SubHeader(text: subTitle, context: context),
        ]),
      ),
    );
  }

  /// Widget that displays the final page.
  Widget _finalPageItem() {
    return Padding(
      // Padding bottom 20 + AppBackButton height.
      padding: const EdgeInsets.only(left: 25, top: 20, right: 25, bottom: 20 + 64),
      child: Center(
        child: SubHeader(text: "Final Page", context: context),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    // Cancel timer.
    showAnimationTimer?.cancel();
    startAnimationTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pageViewItems = [_titleItem(widget.article.title, widget.article.subTitle)];
    pageViewItems.addAll(widget.article.paragraphs.map((text) => _textItem(text)).toList());
    pageViewItems.add(_finalPageItem());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  AppBackButton(onPressed: () => Navigator.pop(context)),
                  const HSpace(),
                  SubHeader(text: "Statusbar", context: context),
                ],
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
                      });
                      startAnimationTimer?.cancel();
                    },
                  ),
                  AnimatedPositioned(
                    bottom: 100,
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
            ],
          ),
        ),
      ),
    );
  }
}
