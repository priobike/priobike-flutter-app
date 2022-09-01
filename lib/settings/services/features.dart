

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:priobike/logging/logger.dart';

class FeatureService with ChangeNotifier {
  final log = Logger('FeatureService');

  /// If the service has been loaded.
  bool hasLoaded = false;

  /// The current git head.
  late String gitHead;

  /// The current git commit id.
  late String gitCommitId;

  /// The current git commit message.
  late String gitCommitMessage;

  /// If internal features can be enabled.
  late bool canEnableInternalFeatures;

  /// if beta features can be enabled.
  late bool canEnableBetaFeatures;

  FeatureService() {
    log.i("FeatureService started.");
  }

  /// Load the service.
  Future<void> load() async {
    if (hasLoaded) return;

    gitHead = (await rootBundle.loadString('.git/HEAD')).trim();
    gitCommitId = (await rootBundle.loadString('.git/ORIG_HEAD')).trim();
    gitCommitMessage = (await rootBundle.loadString('.git/COMMIT_EDITMSG')).trim();

    // Check if the user has the right to enable experimental features.
    canEnableInternalFeatures = gitHead.endsWith("dev");

    // Check if the user has the right to enable beta features.
    canEnableBetaFeatures = gitHead.endsWith("beta") || gitHead.endsWith("dev");

    hasLoaded = true;
    notifyListeners();
  }
}