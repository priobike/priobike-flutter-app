import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';

class CommunityEventView extends StatefulWidget {
  const CommunityEventView({Key? key}) : super(key: key);

  @override
  State<CommunityEventView> createState() => _CommunityEventViewState();
}

class _CommunityEventViewState extends State<CommunityEventView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BoldSubHeader(
          text: 'Community Events',
          context: context,
        ),
        BoldContent(
          text: 'nächstes Event am 26.11.2023',
          context: context,
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
        ),
      ],
    );
  }
}
