import 'package:flutter/material.dart';
import 'package:priobike/common/colors.dart';
import 'package:priobike/common/debug.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/common/layout/tiles.dart';
import 'package:priobike/home/services/shortcuts.dart';
import 'package:priobike/ride/services/position/position.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/models/positioning.dart';
import 'package:priobike/settings/service.dart';
import 'package:provider/provider.dart';

/// Debug these views.
void main() => debug(MultiProvider(
  providers: [
    ChangeNotifierProvider<SettingsService>(
      create: (context) => SettingsService(),
    ),
  ],
  child: const SettingsView(),
));

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override 
  SettingsViewState createState() => SettingsViewState();
}

class SettingsViewState extends State<SettingsView> {
  /// The associated settings service, which is injected by the provider.
  late SettingsService settingsService;

  /// The associated shortcuts service, which is injected by the provider.
  late ShortcutsService shortcutsService;

  /// The associated shortcuts service, which is injected by the provider.
  late PositionService positionService;

  @override
  void didChangeDependencies() {
    settingsService = Provider.of<SettingsService>(context);
    shortcutsService = Provider.of<ShortcutsService>(context);
    positionService = Provider.of<PositionService>(context);
    super.didChangeDependencies();
  }

  /// A callback that is executed when a backend is selected.
  Future<void> onSelectBackend(Backend backend) async {
    // Tell the settings service that we selected the new backend.
    await settingsService.selectBackend(backend);
    // Reset the shortcuts service since these also depend on the backend.
    await shortcutsService.reset();
    Navigator.pop(context);
  }

  /// A callback that is executed when a positioning is selected.
  Future<void> onSelectPositioning(BuildContext ctx, Positioning positioning) async {
    // Tell the settings service that we selected the new backend.
    await settingsService.selectPositioning(positioning);
    // Reset the position service since it depends on the positioning.
    await positionService.reset();
    Navigator.pop(ctx);
  }

  Widget renderBackendSelection() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Tile(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24), 
          bottomLeft: Radius.circular(24)
        ),
        fill: Colors.white,
        content: Row(children: [
          BoldContent(text: "Testort"),
          const HSpace(),
          Flexible(child: Content(text: settingsService.backend.region), fit: FlexFit.tight),
          SmallIconButton(icon: Icons.expand_more, onPressed: () {
            showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
              return Container(
                height: MediaQuery.of(context).size.height / 2,
                color: Colors.white,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: Backend.values.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Tile(fill: AppColors.lightGrey, content: Row(children: [
                        Flexible(child: Content(text: Backend.values[index].region), fit: FlexFit.tight),
                        Expanded(child: Container()),
                        SmallIconButton(
                          icon: Backend.values[index] == settingsService.backend 
                            ? Icons.check 
                            : Icons.check_box_outline_blank, 
                          onPressed: () => onSelectBackend(Backend.values[index]),
                        ),
                      ]))
                    );
                  }
                )
              );
            });
          }),
        ])
      ),
    );
  }

  Widget renderPositioningSelection() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Tile(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24), 
          bottomLeft: Radius.circular(24)
        ),
        fill: Colors.white,
        content: Row(children: [
          BoldContent(text: "Ortung"),
          const HSpace(),
          Flexible(child: Content(text: settingsService.positioning.description), fit: FlexFit.tight),
          SmallIconButton(icon: Icons.expand_more, onPressed: () {
            showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
              return Container(
                height: MediaQuery.of(context).size.height / 2,
                color: Colors.white,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: Positioning.values.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Tile(fill: AppColors.lightGrey, content: Row(children: [
                        Flexible(child: Content(text: Positioning.values[index].description), fit: FlexFit.tight),
                        Expanded(child: Container()),
                        SmallIconButton(
                          icon: Positioning.values[index] == settingsService.positioning 
                            ? Icons.check 
                            : Icons.check_box_outline_blank, 
                          onPressed: () {
                            settingsService.selectPositioning(Positioning.values[index]);
                            Navigator.pop(context);
                          }
                        ),
                      ]))
                    );
                  }
                )
              );
            });
          }),
        ])
      ),
    );
  }

  @override 
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(color: AppColors.lightGrey),
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 128),
            Row(children: [
              AppBackButton(icon: Icons.chevron_left, onPressed: () => Navigator.pop(context)),
              const HSpace(),
              SubHeader(text: "Einstellungen"),
            ]),
            const VSpace(),
            renderBackendSelection(),
            const SmallVSpace(),
            const Padding(padding: EdgeInsets.only(left: 16), child: Divider()),
            const SmallVSpace(),
            renderPositioningSelection(),
            const SmallVSpace(),
            const Padding(padding: EdgeInsets.only(left: 16), child: Divider()),
            const SmallVSpace(),
            Padding(
              padding: const EdgeInsets.only(left: 32), 
              child: Small(text: "Beta-Version PrioBike-App", color: Colors.grey),
            ),
          ],
        ),
      ),
    ]);
  }
}