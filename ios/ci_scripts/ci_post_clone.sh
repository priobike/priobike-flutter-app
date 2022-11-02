#!/bin/sh

# See: https://docs.flutter.dev/deployment/cd#post-clone-script

# The default execution directory of this script is the ci_scripts directory.
cd $CI_WORKSPACE # change working directory to the root of your cloned repo.

# Copy the .netrc to the home directory for mapbox
cp .netrc $HOME/.netrc
chmod 600 $HOME/.netrc

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b 2.10.5 $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Install Flutter artifacts for iOS (--ios), or macOS (--macos) platforms.
flutter precache --ios

# Install Flutter dependencies.
flutter pub get

# Install CocoaPods using gem.
export GEM_HOME=$HOME/.gem
export PATH=$GEM_HOME/bin:$PATH
gem install -n /usr/local/bin cocoapods

# Install CocoaPods dependencies.
cd ios && pod install --allow-root # run `pod install` in the `ios` directory.

exit 0
