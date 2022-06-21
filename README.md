# PrioBike-HH Flutter App

For getting started with development you need to set up your development environment according to the [guide](https://docs.flutter.dev/get-started/install).

## Setting up for iOS development

Make sure to `cp .netrc ~/.netrc` to use MapBox.

## Build APK file for Android

Make sure to include the git commit hash as an build variable. Otherwise it will not show up on the startscreen.

```
flutter build apk --dart-define=COMMIT_ID=$(git rev-parse --short HEAD~)
```


## Documentation for Flutter

For help getting started with Flutter, view the
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
