

import 'package:apro_test/model/bell_model.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'audio_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class BellService {
  static const String _bellTaskName = 'mindfulness_bell_task';

  // final AudioService _audioService = AudioService();
  final NotificationService _notificationService = NotificationService();
  final StorageService _storageService = StorageService();

  Future<void> initialize() async {
    await AudioService.instance.initialize();
    // await _audioService.initialize();
    await _notificationService.initialize();
    await _createUrgentNotificationChannel();
  }

  Future<void> _createUrgentNotificationChannel() async {
    final notifications = FlutterLocalNotificationsPlugin();

    const channel = AndroidNotificationChannel(
      'mindfulness_bell_urgent',
      'Mindfulness Bell Urgent',
      description: 'High priority bell notifications with sound',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<bool> isActive() async {
    final settings = await _storageService.loadActiveSettings();
    if (settings == null) return false;

    final now = DateTime.now();
    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      settings.startTime.hour,
      settings.startTime.minute,
    );
    final endTime = DateTime(
      now.year,
      now.month,
      now.day,
      settings.endTime.hour,
      settings.endTime.minute,
    );

    final adjustedEndTime = endTime.isBefore(startTime)
        ? endTime.add(const Duration(days: 1))
        : endTime;

    return now.isAfter(startTime) && now.isBefore(adjustedEndTime);
  }

  Future<void> startBellSchedule(BellSettings settings) async {
    try {
      await Workmanager().cancelAll(); 

      final now = DateTime.now();
      DateTime startTime = DateTime(
        now.year,
        now.month,
        now.day,
        settings.startTime.hour,
        settings.startTime.minute,
      );
      DateTime endTime = DateTime(
        now.year,
        now.month,
        now.day,
        settings.endTime.hour,
        settings.endTime.minute,
      );

      if (startTime.isBefore(now)) {
        startTime = startTime.add(const Duration(days: 1));
      }

      if (endTime.isBefore(startTime)) {
        endTime = endTime.add(const Duration(days: 1));
      }

      DateTime nextBellTime = startTime;
      int taskId = 0;

      while (nextBellTime.isBefore(endTime)) {
        final delay = nextBellTime.difference(now);

        if (delay.inMilliseconds > 0) {
          await Workmanager().registerOneOffTask(
            '${_bellTaskName}_$taskId',
            _bellTaskName,
            initialDelay: delay,
            inputData: {
              'bellType': settings.bellModel.id,
              'muteInSilentMode': settings.muteInSilentMode,
              'taskId': taskId,
              'bellName': settings.bellModel.name,
              'scheduledTime': nextBellTime.toIso8601String(),
            },
            constraints: Constraints(
              networkType: NetworkType.not_required,
              requiresBatteryNotLow: false,
              requiresCharging: false,
              requiresDeviceIdle: false,
              requiresStorageNotLow: false,
            ),
          );

          debugPrint(
              'Scheduled bell task $taskId for ${nextBellTime.toString()}');
        }

        nextBellTime =
            nextBellTime.add(Duration(minutes: settings.repeatInterval));
        taskId++;
      }

      await Workmanager().registerPeriodicTask(
        'mindfulness_bell_periodic',
        'mindfulness_bell_periodic_task',
        frequency: Duration(minutes: settings.repeatInterval),
        initialDelay: startTime.difference(now),
        inputData: {
          'bellType': settings.bellModel.id,
          'muteInSilentMode': settings.muteInSilentMode,
          'startHour': settings.startTime.hour,
          'startMinute': settings.startTime.minute,
          'endHour': settings.endTime.hour,
          'endMinute': settings.endTime.minute,
          'interval': settings.repeatInterval,
        },
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      await _storageService.saveActiveSettings(settings);

      await _notificationService.showScheduleStartNotification(
        settings.startTime,
        settings.endTime,
        settings.repeatInterval,
      );

      debugPrint('Bell schedule started with ${taskId} tasks');
    } catch (e) {
      debugPrint('Error starting bell schedule: $e');
      rethrow;
    }
  }

  Future<void> stopBellSchedule() async {
    try {
      await Workmanager().cancelAll();
      await _storageService.clearActiveSettings();
      await _notificationService.showScheduleStopNotification();
      debugPrint('Bell schedule stopped');
    } catch (e) {
      debugPrint('Error stopping bell schedule: $e');
      rethrow;
    }
  }

  Future<void> playBellPreview(String bellType) async {
    try {
      await AudioService.instance.playBell(bellType);
    } catch (e) {
      debugPrint('Error playing bell preview: $e');
      rethrow;
    }
  }

  Future<void> handleForegroundBell(BellSettings settings) async {
    try {
      final now = DateTime.now();
      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        settings.startTime.hour,
        settings.startTime.minute,
      );
      final endTime = DateTime(
        now.year,
        now.month,
        now.day,
        settings.endTime.hour,
        settings.endTime.minute,
      );

      final adjustedEndTime = endTime.isBefore(startTime)
          ? endTime.add(const Duration(days: 1))
          : endTime;

      if (now.isAfter(startTime) && now.isBefore(adjustedEndTime)) {
        final minutesSinceStart = now.difference(startTime).inMinutes;
        if (minutesSinceStart % settings.repeatInterval == 0) {
          if (settings.muteInSilentMode) {
            final isSilent = await AudioService.instance.isDeviceInSilentMode();
            if (isSilent) return;
          }

          await AudioService.instance.playBell(settings.bellModel.id);
          await showUrgentBellNotification(settings.bellModel.name);
        }
      }
    } catch (e) {
      debugPrint('Error handling foreground bell: $e');
    }
  }

  Future<void> showUrgentBellNotification(String bellName) async {
    final notifications = FlutterLocalNotificationsPlugin();

    await notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Mindfulness Bell',
      '🔔 $bellName - Time for mindful awareness',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mindfulness_bell_urgent',
          'Mindfulness Bell Urgent',
          channelDescription: 'High priority bell notifications with sound',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          timeoutAfter: 10000,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
    );
  }
}
