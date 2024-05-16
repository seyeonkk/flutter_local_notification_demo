import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class LocalNotification {
  static LocalNotification instance = LocalNotification._();

  LocalNotification._();

  List<AndroidNotificationChannel>? _androidChannels;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize({List<AndroidNotificationChannel>? channels}) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    DarwinInitializationSettings initializationSettingsDarwin =
        const DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    ); // iOS 나중에 권한을 요청하려면, 플러그인을 초기화할 때 위의 모든 항목을 false로 설정

    InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin);

    // 안드로이드 channel 셋팅
    if (Platform.isAndroid && channels != null) {
      // param으로 들어온 channel로 갈아치우기
      await _configureAndroidChannels(channels);

      AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        _androidChannels = await androidPlugin.getNotificationChannels();
      }
    }

    await _plugin.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      // [iOS(지원되는 모든 버전)] 알림 권한 요청
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      // Android 13(API 레벨 33)부터 앱은 이제 사용자가 앱에 알림 표시 권한을 부여할지 결정할 수 있는 메시지를 표시할 수 있다.
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> showNotification(NotificationParams params) async {
    AndroidNotificationChannel? targetChannel;
    if (_androidChannels?.isNotEmpty ?? false) {
      if (params.channelId != null) {
        targetChannel = _androidChannels
            ?.firstWhereOrNull((channel) => channel.id == params.channelId);
      }
    } else {
      // Android 8.0 이상에 필요한 채널 세부정보가 포함됨
      targetChannel = AndroidNotificationChannel(
          'flutter_local_notification', 'flutter_local_notification', // title
          importance: Importance.high,
          enableLights: true,
          enableVibration: false,
          showBadge: true,
          sound: RawResourceAndroidNotificationSound(
              params.sound ?? 'default_sound'),
          playSound: true);
    }
    if (targetChannel == null) {
      return;
    }

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      targetChannel.id,
      targetChannel.name,
      channelDescription: targetChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      color: params.color,
      icon: params.icon,
      playSound: targetChannel.playSound,
      enableVibration: targetChannel.enableVibration,
      //sound: targetChannel.sound,
    );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(threadIdentifier: 'thread_id');

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
    await _plugin.show(
      params.messageId,
      params.title ?? 'scheduled title',
      params.body ?? 'scheduled body',
      notificationDetails,
    );
  }

  Future<void> cancelNotification(int messageId) async {
    await _plugin.cancel(messageId);
  }

  Future<void> zonedScheduleNotification(
      ScheduledNotificationParams params) async {
    AndroidNotificationChannel? targetChannel;
    if (_androidChannels?.isNotEmpty ?? false) {
      if (params.channelId != null) {
        targetChannel = _androidChannels
            ?.firstWhereOrNull((channel) => channel.id == params.channelId);
      }
    } else {
      // Android 8.0 이상에 필요한 채널 세부정보가 포함됨
      targetChannel = AndroidNotificationChannel(
          'flutter_local_notification', 'flutter_local_notification', // title
          importance: Importance.high,
          enableLights: true,
          enableVibration: false,
          showBadge: true,
          sound: RawResourceAndroidNotificationSound(
              params.sound ?? 'default_sound'),
          playSound: true);
    }
    if (targetChannel == null) {
      return;
    }

    await _plugin.zonedSchedule(
        params.messageId,
        params.title ?? 'scheduled title',
        params.body ?? 'scheduled body',
        //tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
        tz.TZDateTime(tz.local, params.year, params.month, params.day,
                params.hour, params.minute)
            .subtract(Duration(
                days: params.durationDay,
                hours: params.durationHour,
                minutes: params.durationMin)),
        NotificationDetails(
            android: AndroidNotificationDetails(
          targetChannel.id,
          targetChannel.name,
          channelDescription: targetChannel.description,
        )),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  Future<void> _configureAndroidChannels(
      List<AndroidNotificationChannel> channelInfo) async {
    AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) {
      return;
    }
    // 이미 만들어져있는 channel 중 필요하지 않은 것 (전달된 channelInfo 에 없는 것) 은 삭제한다.
    // channelInfo에 있는 것만 살림.
    List<AndroidNotificationChannel>? currentChannels =
        await androidPlugin.getNotificationChannels();

    List<String> channelIds =
        channelInfo.map((e) => e.id).toList(growable: false);
    if (currentChannels != null) {
      await Future.forEach(currentChannels, (channel) async {
        if (!channelIds.contains(channel.id)) {
          await androidPlugin.deleteNotificationChannel(channel.id);
        }
      });
    }

    // 전달된 channelInfo 중 이미 존재하지 않는 것들은 새로 만든다.
    await Future.forEach(
      channelInfo,
      (info) async {
        if (currentChannels?.firstWhereOrNull(
                (currentChannel) => currentChannel.id == info.id) ==
            null) {
          await androidPlugin.createNotificationChannel(
            AndroidNotificationChannel(
              info.id,
              info.name,
              description: info.description,
              importance: Importance.high,
              enableLights: true,
              enableVibration: info.enableVibration,
              vibrationPattern: info.vibrationPattern,
              showBadge: true,
              sound: info.sound,
              playSound: info.playSound,
            ),
          );
        }
      },
    );
  }

  Future<void> getAndroidChannels() async {
    AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) {
      return;
    }
    List<AndroidNotificationChannel>? currentChannels =
    await androidPlugin.getNotificationChannels();

    final List<PendingNotificationRequest> pendingNotificationRequests =
    await _plugin.pendingNotificationRequests();

    print('등록된 안드로이드 채널 목록 $currentChannels');
    print('처리 예정인 알림 목록 $pendingNotificationRequests');
  }
}

class ScheduledNotificationParams {
  final int messageId;
  final String? channelId;
  final String? title;
  final String? body;
  final String? payload;
  final String? icon;
  final String? largeIcon;
  final Color? color;
  final String? sound;
  final bool colorized;
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int durationDay;
  final int durationHour;
  final int durationMin;

  ScheduledNotificationParams({
    required this.messageId,
    this.channelId,
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    this.title,
    this.body,
    this.payload,
    this.icon,
    this.largeIcon,
    this.color,
    this.sound,
    this.colorized = false,
    this.durationDay = 0,
    this.durationHour = 0,
    this.durationMin = 0,
  });
}

class NotificationParams {
  final int messageId;
  final String? channelId;
  final String? title;
  final String? body;
  final String? payload;
  final String? icon;
  final String? largeIcon;
  final Color? color;
  final String? sound;
  final bool colorized;

  NotificationParams({
    required this.messageId,
    this.channelId,
    this.title,
    this.body,
    this.payload,
    this.icon,
    this.largeIcon,
    this.color,
    this.sound,
    this.colorized = false,
  });
}
