# PrioBike-HH Flutter App

<p align="left">
  <img width="200" src="https://github.com/priobike/priobike-flutter-app/assets/27271818/096b5754-b37b-4dcb-ad76-e72edc38fc94">
  <img width="200" src="https://github.com/priobike/priobike-flutter-app/assets/27271818/32c799f9-80a5-4fcf-92c8-7ee9079dc1bd">
  <img width="200" src="https://github.com/priobike/priobike-flutter-app/assets/27271818/c2595445-dbd4-461d-9240-a9764de60faf">
</p>

<h4>The PrioBike app gives speed advisories to cyclists in Hamburg to catch green lights. It is developed by TU Dresden and currently in open beta.</h4>

# Download

The PrioBike app is available for download:
- On Google Play: https://play.google.com/store/apps/details?id=de.tudresden.priobike&hl=de 
- On App Store: https://apps.apple.com/de/app/priobike/id1634224594

# Quickstart

**Required Flutter Version: `3.19.6`**

For getting started with development you need to set up your development environment according to
the [guide](https://docs.flutter.dev/get-started/install).

## Setting up for iOS development

Make sure to `cp .netrc.example ~/.netrc` and replace `<your mapbox download token>` in `~/.netrc` with your MapBox secret.

## Setting up for Android development

Make sure to `cp android/gradle.properties.example android/gradle.properties` and replace
`<your mapbox download token>` in `android/gradle.properties` with your MapBox secret.

Also make sure to `cp android/key.properties.example android/key.properties` and `cp android/fastlane/example-keystore.jks android/fastlane/keystore.jks` to be able to sign the app for local release builds. This is different from our Google Play upload keystore and therefore not confidential.

## Continuous Delivery

- On push to `dev`, a build workflow will be triggered to distribute the app to our internal testing at Testflight and Playstore.
- On push to `beta-x`, a build workflow will be triggered to distribute the app to the closed (later open) beta test tracks at Testflight and Playstore.
- When tagging a commit on the `dev` branch with the naming scheme `release-vX.X.X`, a build workflow will be triggered to distribute the app to the Appstore and Playstore (publicly available).
