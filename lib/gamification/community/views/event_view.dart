import 'package:flutter/material.dart';
import 'package:priobike/common/layout/text.dart';
import 'package:priobike/gamification/community/service/community_service.dart';
import 'package:priobike/main.dart';

class CommunityEventView extends StatefulWidget {
  const CommunityEventView({Key? key}) : super(key: key);

  @override
  State<CommunityEventView> createState() => _CommunityEventViewState();
}

class _CommunityEventViewState extends State<CommunityEventView> {
  late CommunityService _communityService;

  @override
  void initState() {
    _communityService = getIt<CommunityService>();
    _communityService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _communityService.removeListener(update);
    super.dispose();
  }

  /// Called when a listener callback of a ChangeNotifier is fired
  void update() => {if (mounted) setState(() {})};

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
        Header(text: _communityService.event?.title ?? 'KEIN EVENT BRO', context: context),
        SubHeader(text: _communityService.locations.length.toString(), context: context)
      ],
    );
  }
}
