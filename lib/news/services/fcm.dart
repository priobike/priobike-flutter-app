import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/settings/models/backend.dart';
import 'package:priobike/settings/services/settings.dart';
import 'package:provider/provider.dart';

class FCM with ChangeNotifier {
  /// The logger for this service.
  final log = Logger("FCM");

  /// The backend for which to display notifications.
  Backend? backendToWatch;

  /// An android notification channel.
  AndroidNotificationChannel? channel;

  /// The flutter local notifications plugin.
  FlutterLocalNotificationsPlugin? plugin;

  /// A boolean indicating if the local notifications plugin is initialized.
  var isInitialized = false;

  FCM() { log.i("Initializing FCM service"); }

  /// Select a new backend to watch.
  Future<void> selectBackend(Backend backend) async {
    backendToWatch = backend;
    notifyListeners();
  }

  /// Initialize the FCM service.
  Future<void> load(BuildContext context) async {
    backendToWatch = Provider.of<Settings>(context, listen: false).backend;

    if (isInitialized) return;

    await Firebase.initializeApp();
    await FirebaseMessaging.instance.requestPermission();
    await FirebaseMessaging.instance.subscribeToTopic("Neuigkeiten");

    channel = const AndroidNotificationChannel(
      'fcm-channel',
      'FCM Notifications',
      description: 'This channel is used for FCM Notifications.',
      importance: Importance.max,
    );

    plugin = FlutterLocalNotificationsPlugin();

    /// Create an Android Notification Channel.
    ///
    /// We use this channel in the `AndroidManifest.xml` file to override the
    /// default FCM channel to enable heads up notifications.
    await plugin
        ?.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel!);

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(onFCMMessage);
    FirebaseMessaging.onMessage.listen(onFCMMessage);

    isInitialized = true;
    notifyListeners();
  }

  /// A handler that is called when an FCM message is received.
  Future<void> onFCMMessage(RemoteMessage msg) async {
    if (!isInitialized) {
      log.w("FCM service not initialized, ignoring message.");
      return;
    }

    log.i("Received FCM message: ${msg.data}");

    // Decide by the environment and the backend if we should display a notification.
    // Update the possibleEnvs with your individual env e.g. dev1 instead of dev when testing.
    final possibleEnvs = ["dev", "staging", "production"];
    final env = msg.data['environment'];
    // Set the env to a custom value in the news service when testing so that not everyone with a debug version receives all notifications.
    if (!possibleEnvs.contains(env)) return;
    if (env == 'dev' && !kDebugMode) return;
    if (env == 'staging' && backendToWatch != Backend.staging) return;
    if (env == 'production' && backendToWatch != Backend.production) return;

    if (msg.notification == null) {
      log.w("FCM message has no notification, ignoring.");
      return;
    }

    if (msg.notification?.android == null) {
      log.w("FCM message has no android notification, ignoring.");
      return;
    }

    plugin!.show(
      msg.notification!.hashCode, 
      msg.notification!.title, 
      msg.notification!.body, 
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel!.id, 
          channel!.name, 
          channelDescription: channel!.description,
          importance: channel!.importance,
          icon: 'icon',
        ),
      ),
    );
  }
}
