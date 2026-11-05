import 'dart:async';
import 'dart:ui' show Color;

import 'package:arrow_escape/features/notifications/domain/reminder_planner.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Reminders scheduled on the device, plus pushes sent from the Firebase
/// console (Messaging → New campaign). Behind an interface so tests and
/// builds without Firebase use [NoNotificationService].
abstract interface class NotificationService {
  Future<void> init();

  /// Asks for the notification permission (Android 13+ / iOS). Returns
  /// whether notifications are allowed.
  Future<bool> requestPermission();

  /// Replaces every scheduled reminder with [reminders].
  Future<void> schedule(List<PlannedReminder> reminders);

  /// Cancels reminders and stops console pushes for this device.
  Future<void> disable();

  /// Re-enables console pushes (reminders come back with [schedule]).
  Future<void> enable();

  /// Screens to open when the player taps a notification.
  Stream<String> get opened;

  /// The route of the notification that launched the app, if any.
  Future<String?> launchRoute();
}

class NoNotificationService implements NotificationService {
  final scheduled = <PlannedReminder>[];
  bool enabled = true;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {
    scheduled
      ..clear()
      ..addAll(reminders);
  }

  @override
  Future<void> disable() async {
    enabled = false;
    scheduled.clear();
  }

  @override
  Future<void> enable() async => enabled = true;

  @override
  Stream<String> get opened => const Stream.empty();

  @override
  Future<String?> launchRoute() async => null;
}

class DeviceNotificationService implements NotificationService {
  DeviceNotificationService({required this.firebase});

  /// Whether Firebase is configured (google-services.json present).
  final bool firebase;

  final _local = FlutterLocalNotificationsPlugin();
  final _opened = StreamController<String>.broadcast();

  static const _channel = AndroidNotificationChannel(
    'reminders',
    'Reminders',
    description: 'Daily challenge, streak and comeback reminders',
    importance: Importance.defaultImportance,
  );

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Daily challenge, streak and comeback reminders',
      icon: 'ic_notification',
      color: Color(0xFF6C4CF5),
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Stream<String> get opened => _opened.stream;

  @override
  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object catch (e) {
      debugPrint('Time zone unavailable, using UTC: $e');
    }
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        // Permission is asked later, at a friendly moment.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) {
        final route = r.payload;
        if (route != null && route.isNotEmpty) _opened.add(route);
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    if (!firebase) return;
    final fcm = FirebaseMessaging.instance;
    // Pushes that arrive while the game is open: Android doesn't show
    // them by itself, so show them as a normal notification.
    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      if (n == null) return;
      _local
          .show(
            id: m.hashCode & 0x7fffffff,
            title: n.title,
            body: n.body,
            notificationDetails: _details,
            payload: _routeOf(m),
          )
          .ignore();
    });
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      final route = _routeOf(m);
      if (route != null) _opened.add(route);
    });
    // Every device also listens on the "all" topic, so a console campaign
    // can target "Topic: all" as well as the whole app.
    unawaited(
      fcm.subscribeToTopic('all').catchError((Object e) {
        debugPrint('FCM topic: $e');
      }),
    );
  }

  /// A console campaign can open a screen: add the custom data key
  /// `route` with `/daily`, `/collection`, `/shop` or `/map`.
  static String? _routeOf(RemoteMessage m) {
    final r = m.data['route'];
    return r is String && r.startsWith('/') ? r : null;
  }

  @override
  Future<String?> launchRoute() async {
    final details = await _local.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      final p = details!.notificationResponse?.payload;
      if (p != null && p.isNotEmpty) return p;
    }
    if (firebase) {
      final m = await FirebaseMessaging.instance.getInitialMessage();
      if (m != null) return _routeOf(m);
    }
    return null;
  }

  @override
  Future<bool> requestPermission() async {
    if (firebase) {
      final s = await FirebaseMessaging.instance.requestPermission();
      return s.authorizationStatus == AuthorizationStatus.authorized ||
          s.authorizationStatus == AuthorizationStatus.provisional;
    }
    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {
    await _local.cancelAllPendingNotifications();
    for (final r in reminders) {
      final at = tz.TZDateTime(
        tz.local,
        r.at.year,
        r.at.month,
        r.at.day,
        r.at.hour,
        r.at.minute,
      );
      if (!at.isAfter(tz.TZDateTime.now(tz.local))) continue;
      await _local.zonedSchedule(
        id: r.id,
        scheduledDate: at,
        notificationDetails: _details,
        // Inexact: needs no special permission and saves battery; it may
        // arrive a few minutes after 7:30.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: r.title,
        body: r.body,
        payload: r.route,
      );
    }
  }

  @override
  Future<void> disable() async {
    await _local.cancelAllPendingNotifications();
    if (!firebase) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('all');
      await FirebaseMessaging.instance.setAutoInitEnabled(false);
      await FirebaseMessaging.instance.unregister();
    } on Object catch (e) {
      debugPrint('FCM disable: $e');
    }
  }

  @override
  Future<void> enable() async {
    if (!firebase) return;
    try {
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      await FirebaseMessaging.instance.register();
      await FirebaseMessaging.instance.subscribeToTopic('all');
    } on Object catch (e) {
      debugPrint('FCM enable: $e');
    }
  }
}

/// Overridden in bootstrap with [DeviceNotificationService].
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NoNotificationService(),
);
