import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';
import 'package:priobike/main.dart';
import 'package:priobike/positioning/services/positioning.dart';
import 'package:priobike/ride/messages/prediction.dart';
import 'package:priobike/ride/services/ride.dart';
import 'package:priobike/routing/models/instruction.dart';
import 'package:priobike/routing/models/route.dart';
import 'package:priobike/settings/services/settings.dart';

class Audio {
  /// An instance for text-to-speach.
  FlutterTts? ftts;

  /// The positioning service instance.
  Ride? ride;

  /// The settings service instance.
  Settings? settings;

  /// The positioning service instance.
  Positioning? positioning;

  /// Whether the audio service is initialized.
  bool initialized = false;

  /// A map that holds information about the last recommendation to check the difference when a new recommendation is received.
  Map<String, Object> lastRecommendation = {};

  /// The current route.
  Route? currentRoute;

  /// Constructor.
  Audio() {
    settings = getIt<Settings>();
    settings!.addListener(_processSettingsUpdates);

    if (settings!.audioInstructionsEnabled) {
      initialized = true;
      _init();
    }
  }

  /// Init the audio service.
  Future<void> _init() async {
    ride ??= getIt<Ride>();
    ride!.addListener(_processRideUpdates);
    positioning ??= getIt<Positioning>();
    positioning!.addListener(_processPositioningUpdates);
  }

  /// Clean up the audio instructions feature.
  Future<void> cleanUp() async {
    ride = null;
    positioning?.removeListener(_processPositioningUpdates);
    positioning = null;
    await resetFTTS();
    lastRecommendation.clear();
  }

  /// Reset the complete audio service.
  Future<void> reset() async {
    settings?.removeListener(_processSettingsUpdates);
    settings = null;
    await cleanUp();
  }

  /// Check for rerouting.
  Future<void> _processRideUpdates() async {
    if (ride?.navigationIsActive != true) return;
    if (ride?.route == null) return;
    // If the current route is null, we won't see a rerouting but the first route.
    if (currentRoute == null) {
      currentRoute = ride!.route;
      return;
    }
    // Rerouting
    if (currentRoute != ride!.route && ride?.route != null) {
      currentRoute = ride?.route;
      if (ftts == null) await _initializeTTS();
      ftts?.speak("Neue Route berechnet");
    }
  }

  /// Check if the audio instructions setting has changed.
  Future<void> _processSettingsUpdates() async {
    if (initialized && !settings!.audioInstructionsEnabled) {
      initialized = false;
      cleanUp();
    } else if (!initialized && settings!.audioInstructionsEnabled) {
      initialized = true;
      _init();
    }
  }

  /// Reset the text-to-speach instance.
  Future<void> resetFTTS() async {
    await ftts?.pause();
    await ftts?.stop();
    await ftts?.clearVoice();
    ftts = null;
  }

  /// Process positioning updates to play audio instructions.
  Future<void> _processPositioningUpdates() async {
    if (settings?.audioInstructionsEnabled != true) {
      return;
    }
    if (ride?.navigationIsActive != true) {
      return;
    }
    if (ftts == null) {
      await _initializeTTS();
    }
    _playAudioInstruction();
    // _playCountdownWhenWaitingForGreen();
  }

  /// Configure the TTS.
  Future<void> _initializeTTS() async {
    ftts = FlutterTts();

    if (Platform.isIOS) {
      // Use siri voice if available.
      List<dynamic> voices = await ftts!.getVoices;
      if (voices.any((element) => element["name"] == "Helena" && element["locale"] == "de-DE")) {
        await ftts!.setVoice({
          "name": "Helena",
          "locale": "de-DE",
        });
      }

      await ftts!.setSpeechRate(0.55); //speed of speech
      await ftts!.setVolume(1); //volume of speech
      await ftts!.setPitch(1); //pitch of sound
      await ftts!.awaitSpeakCompletion(true);
      await ftts!.autoStopSharedSession(false);

      await ftts!.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.duckOthers,
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP
      ]);
    } else {
      // Use android voice if available.
      List<dynamic> voices = await ftts!.getVoices;
      if (voices.any((element) => element["name"] == "de-DE-language" && element["locale"] == "de-DE")) {
        await ftts!.setVoice({
          "name": "de-DE-language",
          "locale": "de-DE",
        });
      }

      await ftts!.setSpeechRate(0.7); //speed of speech
      await ftts!.setVolume(1); //volume of speech
      await ftts!.setPitch(1); //pitch of sound
      await ftts!.awaitSpeakCompletion(true);
    }
  }

  /// Play audio instruction.
  Future<void> _playAudioInstruction() async {
    ride ??= getIt<Ride>();
    positioning ??= getIt<Positioning>();
    if (positioning!.snap == null || ride!.route == null) return;
    if (ftts == null) return;

    Instruction? currentInstruction = ride!.route!.instructions.firstWhereOrNull((element) =>
        !element.executed && vincenty.distance(LatLng(element.lat, element.lon), positioning!.snap!.position) < 20);

    if (currentInstruction != null) {
      currentInstruction.executed = true;

      Iterator it = currentInstruction.text.iterator;
      while (it.moveNext()) {
        // Put this here to avoid music interruption in case that there is no instruction to play.
        if (it.current.type == InstructionTextType.direction) {
          // No countdown information needs to be added.
          await ftts!.speak(it.current.text);
        }
      }
    }
  }
}
