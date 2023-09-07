import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/common/layout/buttons.dart';
import 'package:priobike/common/layout/spacing.dart';
import 'package:priobike/common/layout/text.dart';

/// This view can be used for pages that are accessed from the game hub. It gives them a matching layout, containing
/// a back button and a header with a title and possibly a feature button.
class CustomPage extends StatelessWidget {
  /// Title of the page, displayed in the header.
  final String title;

  /// Content of the page, displayed below the header in a scrollable view.
  final Widget content;

  /// This function is called when the back button is pressed.
  final Function()? backButtonCallback;

  /// The icon for the feature button. If this var is null, there will be no feature button
  final IconData? featureButtonIcon;

  /// This function is called when the feature button is pressed. If this var is null, there will be no feature button.
  final Function()? featureButtonCallback;

  const CustomPage({
    Key? key,
    required this.title,
    this.backButtonCallback,
    this.featureButtonIcon,
    this.featureButtonCallback,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Theme.of(context).colorScheme.background, // Status bar color
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Stack(
            children: [
              // Scroll view with header and content.
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: Theme.of(context).colorScheme.background,
                      child: Column(
                        children: [
                          const SmallVSpace(),
                          // Header and feature button.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const SizedBox(width: 72, height: 64),
                              Expanded(
                                child: SubHeader(
                                  text: title,
                                  context: context,
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              /// Small optional feature button with custom icon.
                              (featureButtonIcon == null || featureButtonCallback == null)
                                  ? const SizedBox(width: 64, height: 0)
                                  : Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: SmallIconButton(
                                        icon: featureButtonIcon!,
                                        onPressed: featureButtonCallback!,
                                        fill: Theme.of(context).colorScheme.background,
                                        splash: Theme.of(context).colorScheme.surface,
                                      ),
                                    ),
                            ],
                          ),

                          const SmallVSpace(),
                        ],
                      ),
                    ),
                    content
                  ],
                ),
              ),
              // Back button on top of the displayed statistics.
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 0.5,
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: AppBackButton(
                        onPressed: backButtonCallback ?? () => Navigator.pop(context),
                      ),
                    ),
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
