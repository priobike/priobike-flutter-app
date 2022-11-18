import 'package:flutter/material.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';

class GeneralNavBarView extends StatelessWidget {
  final String? title;

  const GeneralNavBarView({this.title, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: Theme.of(context).colorScheme.brightness == Brightness.dark ? Colors.white : Colors.black,
      pinned: true,
      snap: false,
      floating: false,
      shadowColor: const Color.fromARGB(26, 0, 37, 100),
      // App back button 64 + 16pxl Padding.
      expandedHeight: 82,
      collapsedHeight: 82,
      toolbarHeight: 82,
      leadingWidth: 64,
      leading: Column(
        children: [
          const SizedBox(height: 8),
          AppBackButton(onPressed: () => Navigator.pop(context)),
          const SizedBox(height: 8)
        ],
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(top: 8, bottom: 8),
        title: Center(
          child: SubHeader(context: context, text: title ?? ""),
        ),
      ),
    );
  }
}
