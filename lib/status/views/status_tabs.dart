import 'package:flutter/material.dart';
import 'package:priobike/main.dart';
import 'package:priobike/status/services/summary.dart';
import 'package:priobike/status/views/status.dart';
import 'package:priobike/status/views/status_history.dart';

enum StatusHistoryTime {
  day,
  week,
}

extension StatusHistoryTimeName on StatusHistoryTime {
  String name() {
    switch (this) {
      case StatusHistoryTime.day:
        return "24 Stunden";
      case StatusHistoryTime.week:
        return "7 Tage";
    }
  }
}

/// Source: https://stackoverflow.com/questions/54522980/flutter-adjust-height-of-pageview-horizontal-listview-based-on-current-child/65332810#65332810
/// License: CC BY-SA 4.0 https://creativecommons.org/licenses/by-sa/4.0/
/// Authors: [Andrzej Chmielewski](https://stackoverflow.com/users/4838100/andrzej-chmielewski) and [LP Square](https://stackoverflow.com/users/10568272/lp-square)
class ExpandablePageView extends StatefulWidget {
  /// List of the Widgets that will be displayed in the pageView.
  final List<Widget> children;

  const ExpandablePageView({
    Key? key,
    required this.children,
  }) : super(key: key);

  @override
  State<ExpandablePageView> createState() => _ExpandablePageViewState();
}

class _ExpandablePageViewState extends State<ExpandablePageView> with TickerProviderStateMixin {
  /// PageController.
  final PageController pageController = PageController(
    viewportFraction: 0.92,
    initialPage: 0,
  );

  /// The list of values for the heights of the widgets.
  late List<double> _heights;

  /// The int for the current page.
  int _currentPage = 0;

  double get _currentHeight => _heights[_currentPage];

  @override
  void initState() {
    _heights = widget.children.map((e) => 0.0).toList();
    super.initState();
    pageController.addListener(() {
      final newPage = pageController.page?.round() ?? 0;
      if (_currentPage != newPage) {
        setState(() => _currentPage = newPage);
      }
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      curve: Curves.easeInOutCubic,
      duration: const Duration(milliseconds: 1000),
      tween: Tween<double>(begin: _heights[0], end: _currentHeight),
      builder: (context, value, child) => SizedBox(height: value, child: child),
      child: PageView(
        controller: pageController,
        allowImplicitScrolling: true,
        clipBehavior: Clip.none,
        children: _sizeReportingChildren
            .asMap() //
            .map((index, child) => MapEntry(index, child))
            .values
            .toList(),
      ),
    );
  }

  List<Widget> get _sizeReportingChildren => widget.children
      .asMap() //
      .map(
        (index, child) => MapEntry(
          index,
          OverflowBox(
            //needed, so that parent won't impose its constraints on the children, thus skewing the measurement results.
            minHeight: 0,
            maxHeight: double.infinity,
            alignment: Alignment.topCenter,
            child: SizeReportingWidget(
              onSizeChange: (size) => setState(() => _heights[index] = size.height),
              child: Align(child: child),
            ),
          ),
        ),
      )
      .values
      .toList();
}

class SizeReportingWidget extends StatefulWidget {
  /// The child of the SizeReportingWidget.
  final Widget child;

  /// The function that is called on size change.
  final ValueChanged<Size> onSizeChange;

  const SizeReportingWidget({
    Key? key,
    required this.child,
    required this.onSizeChange,
  }) : super(key: key);

  @override
  State<SizeReportingWidget> createState() => _SizeReportingWidgetState();
}

class _SizeReportingWidgetState extends State<SizeReportingWidget> {
  /// The Size of the old size.
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySize());
    return widget.child;
  }

  void _notifySize() {
    if (!mounted) {
      return;
    }
    final size = context.size;
    if (_oldSize != size && size != null) {
      _oldSize = size;
      widget.onSizeChange(size);
    }
  }
}

class StatusTabsView extends StatefulWidget {
  const StatusTabsView({Key? key}) : super(key: key);

  @override
  StatusTabsViewState createState() => StatusTabsViewState();
}

class StatusTabsViewState extends State<StatusTabsView> {
  /// The prediction status service, which is injected by the provider.
  final PredictionStatusSummary predictionStatusSummary = getIt<PredictionStatusSummary>();

  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    predictionStatusSummary.addListener(update);
  }

  @override
  void dispose() {
    predictionStatusSummary.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: const ExpandablePageView(
        children: [
          StatusView(),
          StatusHistoryView(time: StatusHistoryTime.day),
          StatusHistoryView(time: StatusHistoryTime.week),
        ],
      ),
    );
  }
}
