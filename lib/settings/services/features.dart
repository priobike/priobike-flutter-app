import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:priobike/logging/logger.dart';

class Feature with ChangeNotifier {
  final log = Logger('Feature');

  /// If the service has been loaded.
  bool hasLoaded = false;

  /// The current git head.
  /// Should only be used for setting the feature set of the app.
  late String _gitHead;

  /// The current git tag. Can be empty if the latest commit is not tagged. Only is set when the get_tag.sh is executed.
  /// Should only be used for setting the feature set of the app.
  late String _gitTag;

  /// The current app name.
  late String appName;

  /// The current app version.
  late String appVersion;

  /// The current app build number.
  late String appBuildNumber;

  /// The current package name.
  late String packageName;

  /// If internal features can be enabled.
  late bool canEnableInternalFeatures;

  /// The used build trigger.
  late String buildTrigger;

  Feature();

  /// Load the service.
  Future<void> load() async {
    if (hasLoaded) return;

    _gitHead = (await rootBundle.loadString('.git/HEAD')).trim();
    _gitTag = (await rootBundle.loadString('git_tag.txt')).trim();

    if (_gitTag.isEmpty) {
      buildTrigger = _gitHead.replaceAll("ref: refs/heads/", "");
    } else {
      buildTrigger = _gitTag;
    }

    // Check if the user has the right to enable experimental features.
    // This is the case, when the branch is not beta or the latest tag is not tagged as a release.
    // (Allow internal features on all development branches.)
    canEnableInternalFeatures = !_gitHead.contains('beta') && !_gitTag.contains('release-');

    final info = await PackageInfo.fromPlatform();
    appName = info.appName;
    appVersion = info.version;
    appBuildNumber = info.buildNumber;
    packageName = info.packageName;

    hasLoaded = true;
    notifyListeners();
  }
}
