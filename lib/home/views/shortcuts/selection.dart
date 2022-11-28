import 'dart:math';

import 'package:flutter/material.dart' hide Shortcuts;
import 'package:priobike/common/animation.dart';
import 'package:priobike/common/layout/ci.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/models/shortcut.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/routingNew/services/routing.dart';
import 'package:provider/provider.dart';

class ShortcutView extends StatelessWidget {
  final bool isHighlighted;
  final bool isLoading;
  final void Function() onPressed;
  final IconData icon;
  final String title;
  final double width;
  final double height;
  final double rightPad;

  const ShortcutView(
      {Key? key,
      this.isHighlighted = false,
      this.isLoading = false,
      required this.onPressed,
      required this.icon,
      required this.title,
      required this.width,
      required this.height,
      required this.rightPad,
      required BuildContext context})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      constraints: BoxConstraints(minWidth: width, maxWidth: width),
      padding: EdgeInsets.only(right: rightPad, bottom: 24),
      child: Tile(
        onPressed: onPressed,
        shadow: isHighlighted ? CI.blue : const Color.fromARGB(255, 0, 0, 0),
        shadowIntensity: isHighlighted ? 0.3 : 0.08,
        padding: const EdgeInsets.all(16),
        content: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: isLoading
                ? [const Expanded(child: Center(child: CircularProgressIndicator()))]
                : [
                    Icon(
                      icon,
                      size: 64,
                      color: isHighlighted
                          ? Colors.white
                          : Theme.of(context).colorScheme.brightness == Brightness.dark
                              ? Colors.grey
                              : Colors.black,
                    ),
                    Expanded(child: Container()),
                    Content(
                      text: title,
                      color: isHighlighted
                          ? Colors.white
                          : Theme.of(context).colorScheme.brightness == Brightness.dark
                              ? Colors.grey
                              : Colors.black,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      context: context,
                    ),
                  ],
          ),
        ),
        fill: isHighlighted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.background,
        splash: isHighlighted ? Colors.white : Colors.black,
      ),
    );
  }
}

class ShortcutsView extends StatefulWidget {
  /// A callback that will be executed when the shortcut was selected.
  final void Function(Shortcut shortcut) onSelectShortcut;

  /// A callback that will be executed when free routingOLD is started.
  final void Function() onStartFreeRouting;

  const ShortcutsView({
    required this.onSelectShortcut,
    required this.onStartFreeRouting,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => ShortcutsViewState();
}

class ShortcutsViewState extends State<ShortcutsView> {
  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts ss;

  /// The associated routingOLD service, which is injected by the provider.
  late Routing rs;

  /// The left padding.
  double leftPad = 24;

  /// If the user has scrolled.
  bool hasScrolled = false;

  /// The scroll controller.
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(
      () {
        if (scrollController.offset > 0) {
          hasScrolled = true;
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    ss = Provider.of<Shortcuts>(context);
    rs = Provider.of<Routing>(context);
    WidgetsBinding.instance!.addPostFrameCallback((_) => triggerAnimations());
    super.didChangeDependencies();
  }

  /// Trigger the animation of the status view.
  Future<void> triggerAnimations() async {
    // Add some delay before we start the animation.
    await Future.delayed(const Duration(milliseconds: 5000));
    if (!hasScrolled) setState(() => leftPad = 24);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!hasScrolled) setState(() => leftPad = 22);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!hasScrolled) setState(() => leftPad = 24);
  }

  @override
  Widget build(BuildContext context) {
    const double shortcutRightPad = 16;
    final shortcutWidth = (MediaQuery.of(context).size.width / 2) - shortcutRightPad;
    final shortcutHeight = max(shortcutWidth - (shortcutRightPad * 3), 128.0);

    List<Widget> views = [
      AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.only(left: leftPad),
      ),
      ShortcutView(
        onPressed: () {
          if (!rs.isFetchingRoute) widget.onStartFreeRouting();
        },
        isHighlighted: true,
        icon: Icons.map_rounded,
        title: "Freies Routing starten",
        width: shortcutWidth,
        height: shortcutHeight,
        rightPad: shortcutRightPad,
        context: context,
      ),
    ];

    views += ss.shortcuts
            ?.map(
              (shortcut) => ShortcutView(
                onPressed: () {
                  // Allow only one shortcut to be fetched at a time.
                  if (!rs.isFetchingRoute) widget.onSelectShortcut(shortcut);
                },
                isLoading: (rs.selectedWaypoints == shortcut.waypoints) && rs.isFetchingRoute,
                icon: Icons.route_outlined,
                title: shortcut.name,
                width: shortcutWidth,
                height: shortcutHeight,
                rightPad: shortcutRightPad,
                context: context,
              ),
            )
            .toList() ??
        [];

    List<Widget> animatedViews = views
        .asMap()
        .entries
        .map(
          (e) => BlendIn(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            delay: Duration(milliseconds: 250 /* Time until shortcuts are shown */ + 250 * e.key),
            child: e.value,
          ),
        )
        .toList();

    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(children: animatedViews),
    );
  }
}
