#!/bin/sh

# See: https://docs.flutter.dev/deployment/cd#post-clone-script

# print commands before executing them
set -x

# Fail on any error.
set -e

# The default execution directory of this script is the ci_scripts directory.
cd $CI_PRIMARY_REPOSITORY_PATH # change working directory to the root of your cloned repo.

# Write the MAPBOX_DOWNLOADS_TOKEN to the .netrc file.
echo "$NETRC_BASE64" | base64 --decode > $HOME/.netrc
chmod 600 $HOME/.netrc

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b 3.19.6 $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Install Flutter artifacts for iOS (--ios), or macOS (--macos) platforms.
flutter precache --ios

# Install Flutter dependencies.
flutter pub get

# Install CocoaPods using brew.
brew install cocoapods

# Install CocoaPods dependencies.
cd ios && pod install # run `pod install` in the `ios` directory.

exit 0
