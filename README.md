# PrioBike-HH Flutter App

**Required Flutter Version: `2.10.5`**

For getting started with development you need to set up your development environment according to the [guide](https://docs.flutter.dev/get-started/install).

## Setting up for iOS development

Make sure to `cp .netrc ~/.netrc` to use MapBox.

## Generating App Icons and Splash Screen

This project uses [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) to generate app icons. To generate them, replace `assets/icon.png` and then run: `flutter pub run flutter_launcher_icons:main`.

To provide a splash screen, this project uses [flutter_native_splash](https://pub.dev/packages/flutter_native_splash). To generate the splash screens for Android and iOS, replace `assets/splash.png` and then run: `flutter pub run flutter_native_splash:create`.

## Continuous Delivery

![Flutter App Development](https://user-images.githubusercontent.com/27271818/208384012-5259dae4-abad-4705-9390-ac1bcf007ac7.png)

On push to `dev` or `beta`, a build workflow will be triggered to distribute our app.

## Documentation for Flutter

For help getting started with Flutter, view the
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Troubleshooting

### IOS-Simulator doesn't work on M1-Macs

Currently (Nov. 2022) XCode still has legacy applications that don't fully work on Apple's M1-Chips. One such application is the iOS-Simulator. There are [several options](https://blog.sudeium.com/2021/06/18/build-for-x86-simulator-on-apple-silicon-macs/) to fix this.

The easiest fix is to change `PrioBike/priobike-flutter-app/ios/Pods/Pods.xcodeproj/project.pbxproj`:
```diff
- VALID_ARCHS[sdk=iphonesimulator*] = "$(ARCHS_STANDARD)";
+ VALID_ARCHS[sdk=iphonesimulator*] = x86_64;
```

Also, if there is a problem with the iPhoneOS-Deployment-Target, change it to 11.0 in the same file:
```diff
- IPHONEOS_DEPLOYMENT_TARGET = 8.0;
- IPHONEOS_DEPLOYMENT_TARGET = 9.0;
- IPHONEOS_DEPLOYMENT_TARGET = 10.0;
+ IPHONEOS_DEPLOYMENT_TARGET = 11.0;
```
