import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/services/profile_service.dart';
import 'package:priobike/main.dart';

class FeatureCard extends StatefulWidget {
  final String featureKey;

  final Widget featureEnabledWidget;

  final Widget featureDisabledWidget;

  const FeatureCard({
    Key? key,
    required this.featureKey,
    required this.featureEnabledWidget,
    required this.featureDisabledWidget,
  }) : super(key: key);

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  /// Game settings service required to check whether the user has set their challenge goals.
  late GameProfileService _profileService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  bool get featureEnabled => _profileService.enabledFeatures.contains(widget.featureKey);

  @override
  void initState() {
    _profileService = getIt<GameProfileService>();
    _profileService.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    _profileService.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (featureEnabled) {
      return widget.featureEnabledWidget;
    } else {
      return widget.featureDisabledWidget;
    }
  }
}