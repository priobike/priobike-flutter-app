import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/settings/models/backend.dart';

class FCM {
  /// The logger for this service.
  static final log = Logger("FCM");

  /// An android notification channel.
  static AndroidNotificationChannel? channel;

  /// The flutter local notifications plugin.
  static FlutterLocalNotificationsPlugin? plugin;

  /// A boolean indicating if the local notifications plugin is initialized.
  static bool isInitialized = false;

  FCM() {
    log.i("Initializing FCM service");
  }

  /// Initialize the FCM service.
  static Future<void> load(Backend backend) async {
    if (isInitialized) return;

    await Firebase.initializeApp();
    await FirebaseMessaging.instance.requestPermission();
    // Don't use await here since it will wait until an internet connection is established.
    if (kDebugMode) {
      FirebaseMessaging.instance.subscribeToTopic("dev");
    } else {
      if (backend == Backend.production) {
        FirebaseMessaging.instance.subscribeToTopic("production");
      } else if (backend == Backend.staging) {
        FirebaseMessaging.instance.subscribeToTopic("staging");
      }
    }

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
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(onFCMMessage);
    FirebaseMessaging.onMessage.listen(onFCMMessage);

    isInitialized = true;
  }

  /// A handler that is called when an FCM message is received.
  static Future<void> onFCMMessage(RemoteMessage msg) async {
    if (!isInitialized) {
      log.w("FCM service not initialized, ignoring message.");
      return;
    }

    log.i("Received FCM message: ${msg.data}");

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
