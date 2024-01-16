# PrioBike-HH Flutter App

**Required Flutter Version: `3.16.4`**

For getting started with development you need to set up your development environment according to
the [guide](https://docs.flutter.dev/get-started/install).

## Setting up for iOS development

Make sure to `cp .netrc ~/.netrc` to use MapBox.

## Generating App Icons and Splash Screen

This project uses [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) to
generate app icons. To generate them, replace `assets/icon.png` and then
run: `flutter pub run flutter_launcher_icons:main`.

To provide a splash screen, this project
uses [flutter_native_splash](https://pub.dev/packages/flutter_native_splash). To generate the splash
screens for Android and iOS, replace `assets/splash.png` and then
run: `flutter pub run flutter_native_splash:create`.

### Note: Android 12 Splash Screen Support

Since Android 12 implements its own splash screen, a solution must be found for this version, since
otherwise there will be two different splash screens. It was decided to keep the Android 12 splash
screen (since this one can't be deactivated) and replace the second unwanted splash screen with a
uniform color. For this purpose, a separate `launch_background` drawable file was created for
Android v31. More information can be
found [here](https://pub.dev/packages/flutter_native_splash#android-12-support).

```diff
+ android/app/src/main/res/drawable-night-v31/launch_background;
+ android/app/src/main/res/drawable-v31/launch_background;
```

## Continuous Delivery

![Flutter App Development](https://user-images.githubusercontent.com/27271818/208384012-5259dae4-abad-4705-9390-ac1bcf007ac7.png)

On push to `dev` or `beta`, a build workflow will be triggered to distribute our app.

## Clean up Android logs

Since we use the textureView for our Mapbox Maps, the log gets spammed with the following message:

```
updateAcquireFence: Did not find frame.
```

According to [this](https://github.com/flutter/flutter/issues/104268#issuecomment-1134964433), this
is meaningless for us. Therefore we can use filters in our IDE to exclude this message from the
log (ensuring a clean log).

For Android Studio include the following filter when using Logcat:

```
package=:de.tudresden.priobike -message:"updateAcquireFence: Did not find frame."
```

For Visual Studio Code it is not that important because it groups the messages already such that
they are not that annoying. To exclude those use the following filter:

```
!updateAcquireFence: Did not find frame.
```

## Documentation for Flutter

For help getting started with Flutter, view the
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Troubleshooting

### IOS-Simulator doesn't work on M1-Macs

Currently (Nov. 2022) XCode still has legacy applications that don't fully work on Apple's M1-Chips.
One such application is the iOS-Simulator. There
are [several options](https://blog.sudeium.com/2021/06/18/build-for-x86-simulator-on-apple-silicon-macs/)
to fix this.

The easiest fix is to
change `PrioBike/priobike-flutter-app/ios/Pods/Pods.xcodeproj/project.pbxproj`:

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
