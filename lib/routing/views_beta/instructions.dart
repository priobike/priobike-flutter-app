import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/main.dart';
import 'package:priobike/routing/messages/graphhopper.dart';
import 'package:priobike/routing/services/routing.dart';
import 'package:priobike/routing/views_beta/widgets/arrow.dart';

class InstructionsView extends StatefulWidget {
  const InstructionsView({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => InstructionsViewState();
}

class InstructionsViewState extends State<InstructionsView> {
  /// The associated routing service, which is injected by the provider.
  late Routing routing;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    routing = getIt<Routing>();
    routing.addListener(update);
  }

  @override
  void dispose() {
    routing.removeListener(update);
    super.dispose();
  }

  /// The widget that displays an instruction.
  _instructionItem(BuildContext context, GHInstruction ghInstruction, MediaQueryData frame) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            flex: 4,
            child: Row(
              children: [
                const SizedBox(width: 10),
                NavigationArrow(
                  sign: ghInstruction.sign,
                  width: 50,
                ),
                const SizedBox(width: 20),
                Content(text: "${ghInstruction.distance.toStringAsFixed(0)} m", context: context),
                const SizedBox(width: 20),
              ],
            ),
          ),
          Flexible(
            flex: 5,
            child: Content(text: ghInstruction.text, context: context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = MediaQuery.of(context);

    List<Widget> instructionItems = [];
    if (routing.selectedRoute != null) {
      for (GHInstruction ghInstruction in routing.selectedRoute!.path.instructions) {
        instructionItems.add(_instructionItem(context, ghInstruction, frame));
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Show status bar in opposite color of the background.
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Hero(
                    tag: 'appBackButton',
                    child: AppBackButton(
                      icon: Icons.chevron_left_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: Center(
                        child: BoldSubHeader(
                          text: "Anweisungen",
                          context: context,
                        ),
                      ),
                    ),
                  ),

                  /// To center the text
                  const SizedBox(width: 80),
                ]),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: instructionItems,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
