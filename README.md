# PrioBike Flutter App

A new Flutter project.

## Installation

For the Mapbox SDK for iOS two tokens are required:
https://docs.mapbox.com/ios/maps/guides/install/

- the public access token needs to be integrated in Info.plist
  pk.eyJ1Ijoic3RlcGhkaW4iLCJhIjoiY2t0OGxmcGZiMTM0cjJ3bzdkdHF1eWtpaSJ9.c3yOObWXOX-PD06z0_oXaA
  pk.eyJ1Ijoic3RlcGhkaW4iLCJhIjoiY2swbTVvY2JxMDAzYzNqcXpsbnI4M2NsdyJ9.\_8rGj8sjsLlqkOKG7z_PCQ

- the secret access token needs to be stored in a file .netrc in the home directory
  sk.eyJ1Ijoic3RlcGhkaW4iLCJhIjoiY2t0OGxqcXppMHd0YTJucGNwcTA3NWt5MSJ9.r0BCH8FF26aXJJy2VWVyMg

in file .netrc:

machine api.mapbox.com
login mapbox
password <secret access token>

### Endpoint Configuration

The endpoint needs to be configured as:
https://gitlab.vlpz.vkw.tu-dresden.de/priobike/priobike-wiki/-/wikis/Nachrichten-zwischen-den-Komponenten

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Project Setup
### iOS/Xcode

It is important to open Runner.xcworkspace as project not Runner.xcodeproj in ios/Runner.


