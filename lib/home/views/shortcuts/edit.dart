import 'package:flutter/material.dart' hide Shortcuts;
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/general_nav.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:provider/provider.dart';

class ShortcutsEditView extends StatefulWidget {
  const ShortcutsEditView({Key? key}) : super(key: key);

  @override
  ShortcutsEditViewState createState() => ShortcutsEditViewState();
}

class ShortcutsEditViewState extends State<ShortcutsEditView> {
  /// The associated shortcuts service, which is injected by the provider.
  late Shortcuts shortcuts;

  /// The ScrollController for syncing reorderable list and custom scroll.
  final ScrollController scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    shortcuts = Provider.of<Shortcuts>(context);
    super.didChangeDependencies();
  }

  /// A callback that is executed when the order of the shortcuts change.
  Future<void> onChangeShortcutOrder(int oldIndex, int newIndex) async {
    if (shortcuts.shortcuts == null || shortcuts.shortcuts!.isEmpty) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final reorderedShortcuts = shortcuts.shortcuts!.toList();
    final shortcut = reorderedShortcuts.removeAt(oldIndex);
    reorderedShortcuts.insert(newIndex, shortcut);

    shortcuts.updateShortcuts(reorderedShortcuts, context);
  }

  /// A callback that is executed when a shortcut should be deleted.
  Future<void> onDeleteShortcut(int idx) async {
    if (shortcuts.shortcuts == null || shortcuts.shortcuts!.isEmpty) return;

    final newShortcuts = shortcuts.shortcuts!.toList();
    newShortcuts.removeAt(idx);

    shortcuts.updateShortcuts(newShortcuts, context);
  }

  @override
  Widget build(BuildContext context) {
    if (shortcuts.shortcuts == null) return Container();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          top: true,
          child: CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              const GeneralNavBarView(
                title: "Strecken",
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    ReorderableListView(
                      scrollController: scrollController,
                      // physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      proxyDecorator: (proxyWidget, idx, anim) {
                        return proxyWidget;
                      },
                      children: shortcuts.shortcuts!.asMap().entries.map<Widget>(
                        (entry) {
                          return Container(
                            key: Key("$entry.key"),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16, top: 8),
                              child: Tile(
                                fill: Theme.of(context).colorScheme.background,
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
                                content: Row(
                                  children: [
                                    Flexible(
                                        child: BoldContent(
                                          text: entry.value.name,
                                          context: context,
                                        ),
                                        fit: FlexFit.tight),
                                    const HSpace(),
                                    SmallIconButton(
                                      icon: Icons.delete,
                                      onPressed: () => onDeleteShortcut(entry.key),
                                      fill: Theme.of(context).colorScheme.surface,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ).toList(),
                      onReorder: onChangeShortcutOrder,
                    ),
                    const SizedBox(height: 128),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
