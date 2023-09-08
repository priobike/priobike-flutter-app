import 'package:flutter/material.dart';
import 'package:priobike/gamification/common/services/user_service.dart';
import 'package:priobike/main.dart';

class GamificationFeatureView extends StatefulWidget {
  final String featureKey;

  final Widget featureEnabledWidget;

  final Widget featureDisabledWidget;

  const GamificationFeatureView({
    Key? key,
    required this.featureKey,
    required this.featureEnabledWidget,
    required this.featureDisabledWidget,
  }) : super(key: key);

  @override
  State<GamificationFeatureView> createState() => _GamificationFeatureViewState();
}

class _GamificationFeatureViewState extends State<GamificationFeatureView> {
  /// Game settings service required to check whether the user has set their challenge goals.
  late GamificationUserService _profileService;

  /// Called when a listener callback of a ChangeNotifier is fired.
  void update() => {if (mounted) setState(() {})};

  bool get featureEnabled => _profileService.enabledFeatures.contains(widget.featureKey);

  @override
  void initState() {
    _profileService = getIt<GamificationUserService>();
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
