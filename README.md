# PrioBike-HH Flutter App

**Required Flutter Version: `2.10.5`**

For getting started with development you need to set up your development environment according to the [guide](https://docs.flutter.dev/get-started/install).

## Setting up for iOS development

Make sure to `cp .netrc ~/.netrc` to use MapBox.

## Build APK file for Android

Make sure to include the git commit hash as an build variable. Otherwise it will not show up on the startscreen.

```
flutter build apk --dart-define=COMMIT_ID=$(git rev-parse --short HEAD~)
```

## Generating App Icons and Splash Screen

This project uses [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) to generate app icons. To generate them, replace `assets/icon.png` and then run: `flutter pub run flutter_launcher_icons:main`.

To provide a splash screen, this project uses [flutter_native_splash](https://pub.dev/packages/flutter_native_splash). To generate the splash screens for Android and iOS, replace `assets/icon.png` and then run: `flutter pub run flutter_native_splash:create`.

## Documentation for Flutter

For help getting started with Flutter, view the
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
