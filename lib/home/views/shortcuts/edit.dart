import 'package:flutter/material.dart';
import 'package:priobike/common/colors.dart';
import 'package:priobike/common/layout/buttons.dart';
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
  late ShortcutsService shortcutsService;

  @override
  void didChangeDependencies() {
    shortcutsService = Provider.of<ShortcutsService>(context);
    super.didChangeDependencies();
  }

  /// A callback that is executed when the order of the shortcuts change.
  Future<void> onChangeShortcutOrder(int oldIndex, int newIndex) async {
    if (shortcutsService.shortcuts == null || shortcutsService.shortcuts!.isEmpty) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final reorderedShortcuts = shortcutsService.shortcuts!.toList();
    final shortcut = reorderedShortcuts.removeAt(oldIndex);
    reorderedShortcuts.insert(newIndex, shortcut);

    shortcutsService.updateShortcuts(reorderedShortcuts, context);
  }

  /// A callback that is executed when a shortcut should be deleted.
  Future<void> onDeleteShortcut(int idx) async {
    if (shortcutsService.shortcuts == null || shortcutsService.shortcuts!.isEmpty) return;

    final newShortcuts = shortcutsService.shortcuts!.toList();
    newShortcuts.removeAt(idx);
    
    shortcutsService.updateShortcuts(newShortcuts, context);
  }

  @override
  Widget build(BuildContext context) {
    if (shortcutsService.shortcuts == null) return Container();
    return Scaffold(body: 
      SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 128),
          Row(children: [
            AppBackButton(icon: Icons.chevron_left, onPressed: () => Navigator.pop(context)),
            const HSpace(),
            SubHeader(text: "Shortcuts"),
          ]),
          ReorderableListView(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            proxyDecorator: (proxyWidget, idx, anim) {
              return proxyWidget;
            },
            children: shortcutsService.shortcuts!.asMap().entries.map<Widget>((entry) {
              return Container(
                key: Key("$entry.key"),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Tile(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24), 
                      bottomLeft: Radius.circular(24)
                    ),
                    fill: Colors.white,
                    content: Row(children: [
                      Flexible(child: BoldContent(text: entry.value.name), fit: FlexFit.tight),
                      const HSpace(),
                      SmallIconButton(
                        icon: Icons.delete, 
                        onPressed: () => onDeleteShortcut(entry.key), 
                        color: Colors.black, 
                        fill: AppColors.lightGrey,
                      ),
                    ]),
                  ),
                )
              );
            }).toList(),
            onReorder: onChangeShortcutOrder,
          ),
          const SizedBox(height: 128),
        ]),
      ),
    );
  }
}