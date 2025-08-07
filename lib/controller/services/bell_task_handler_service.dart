

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("🔔 Background Task Started: $task");
    debugPrint("📱 Input Data: $inputData");

    try {
      switch (task) {
        case 'mindfulness_bell_task':
          return await _handleBellTask(inputData);
        case 'mindfulness_bell_periodic_task':
          return await _handlePeriodicBellTask(inputData);
        default:
          debugPrint("❌ Unknown task: $task");
          return false;
      }
    } catch (e) {
      debugPrint("❌ Background task error: $e");
      return false;
    }
  });
}

Future<bool> _handleBellTask(Map<String, dynamic>? inputData) async {
  try {
    if (inputData == null) {
      debugPrint("❌ No input data");
      return false;
    }

    final bellType = inputData['bellType'] as String? ?? 'singing_bowl';
    final muteInSilentMode = inputData['muteInSilentMode'] as bool? ?? false;
    final taskId = inputData['taskId'] as int? ?? 0;

    debugPrint("🔔 Showing Bell Notification: $bellType (Task: $taskId)");

    final notifications = FlutterLocalNotificationsPlugin();
    await _initializeNotifications(notifications);

    await _createBellNotificationChannel(notifications, bellType);

    await _showBellNotification(notifications, bellType, muteInSilentMode);

    debugPrint("✅ Bell notification shown successfully");
    return true;
  } catch (e) {
    debugPrint("❌ Error in bell task: $e");
    return false;
  }
}

Future<bool> _handlePeriodicBellTask(Map<String, dynamic>? inputData) async {
  try {
    if (inputData == null) {
      debugPrint("❌ No input data for periodic task");
      return false;
    }

    final bellType = inputData['bellType'] as String? ?? 'singing_bowl';
    final muteInSilentMode = inputData['muteInSilentMode'] as bool? ?? false;
    final startHour = inputData['startHour'] as int? ?? 0;
    final startMinute = inputData['startMinute'] as int? ?? 0;
    final endHour = inputData['endHour'] as int? ?? 23;
    final endMinute = inputData['endMinute'] as int? ?? 59;
    final interval = inputData['interval'] as int? ?? 30;

    debugPrint("🔔 Processing periodic bell task: $bellType");

    final now = DateTime.now();
    final startTime =
        DateTime(now.year, now.month, now.day, startHour, startMinute);
    final endTime = DateTime(now.year, now.month, now.day, endHour, endMinute);

    if (now.isBefore(startTime) || now.isAfter(endTime)) {
      debugPrint("⏰ Current time outside bell schedule range");
      return true; 
    }

    final notifications = FlutterLocalNotificationsPlugin();
    await _initializeNotifications(notifications);

    await _createBellNotificationChannel(notifications, bellType);

    await _showBellNotification(notifications, bellType, muteInSilentMode);

    debugPrint("✅ Periodic bell notification shown successfully");
    return true;
  } catch (e) {
    debugPrint("❌ Error in periodic bell task: $e");
    return false;
  }
}

Future<void> _initializeNotifications(
    FlutterLocalNotificationsPlugin notifications) async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iOSSettings = DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );
  const settings = InitializationSettings(
    android: androidSettings,
    iOS: iOSSettings,
  );

  await notifications.initialize(settings);
}

Future<void> _createBellNotificationChannel(
    FlutterLocalNotificationsPlugin notifications, String bellType) async {
  final android = notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  if (android != null) {
    final bellConfig = _getBellConfig(bellType);

    await android.createNotificationChannel(
      AndroidNotificationChannel(
        bellConfig['channelId'],
        bellConfig['channelName'],
        description: bellConfig['description'],
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        sound: bellConfig['sound'],
        showBadge: true,
      ),
    );
  }
}

Future<void> _showBellNotification(
    FlutterLocalNotificationsPlugin notifications,
    String bellType,
    bool muteInSilentMode) async {
  final bellConfig = _getBellConfig(bellType);

  await notifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'Mindfulness Bell 🔔',
    '${bellConfig['bellName']} - Time for mindful awareness',
    NotificationDetails(
      android: AndroidNotificationDetails(
        bellConfig['channelId'],
        bellConfig['channelName'],
        channelDescription: bellConfig['description'],
        importance: Importance.max,
        priority: Priority.max,
        audioAttributesUsage: AudioAttributesUsage.alarm, 


        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF8B5FBF),

        playSound: !muteInSilentMode,
        sound: !muteInSilentMode ? bellConfig['sound'] : null,
        enableVibration: true,
        enableLights: true,
        ledColor: const Color(0xFF8B5FBF),
        ledOnMs: 1000, 
        ledOffMs: 500, 

        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        timeoutAfter: 15000,
        ongoing: false,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,

        styleInformation: BigTextStyleInformation(
          'Take a moment to breathe deeply and center yourself in mindful awareness. This gentle bell invites you to pause and reconnect with the present moment.',
          htmlFormatBigText: true,
          contentTitle: 'Mindfulness Bell 🔔',
          htmlFormatContentTitle: true,
          summaryText: bellConfig['bellName'],
        ),

        actions: [
          const AndroidNotificationAction(
            'dismiss_action',
            'Dismiss',
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: !muteInSilentMode,
        sound: !muteInSilentMode ? bellConfig['iOSSound'] : null,
        interruptionLevel: InterruptionLevel.critical,
        subtitle: bellConfig['bellName'],
        threadIdentifier: 'mindfulness_bell',
        categoryIdentifier: 'MINDFULNESS_BELL_CATEGORY',

      ),
    ),
  );
}

Map<String, dynamic> _getBellConfig(String bellType) {
  switch (bellType) {
    case 'singing_bowl':
      return {
        'channelId': 'singing_bowl_channel',
        'channelName': 'Singing Bowl Bell',
        'description': 'Mindfulness bell with singing bowl sound',
        'bellName': 'Singing Bowl',
        'sound': const RawResourceAndroidNotificationSound(
            'mixkit_bell_tick_tock_timer'),
        'iOSSound': 'mixkit_bell_tick_tock_timer.wav',
      };
    case 'ohm_bell':
      return {
        'channelId': 'ohm_bell_channel',
        'channelName': 'Ohm Bell',
        'description': 'Mindfulness bell with ohm bell sound',
        'bellName': 'Ohm Bell',
        'sound': const RawResourceAndroidNotificationSound(
            'mixkit_melodic_classic_doorbell'),
        'iOSSound': 'mixkit_melodic_classic_doorbell.wav',
      };
    case 'gong':
      return {
        'channelId': 'gong_channel',
        'channelName': 'Gong Bell',
        'description': 'Mindfulness bell with gong sound',
        'bellName': 'Gong',
        'sound':
            const RawResourceAndroidNotificationSound('mixkit_service_bell'),
        'iOSSound': 'mixkit_service_bell.wav',
      };
    default:
      return {
        'channelId': 'default_bell_channel',
        'channelName': 'Default Bell',
        'description': 'Default mindfulness bell sound',
        'bellName': 'Bell',
        'sound': const RawResourceAndroidNotificationSound(
            'mixkit_bell_tick_tock_timer'),
        'iOSSound': 'mixkit_bell_tick_tock_timer.wav',
      };
  }
}
