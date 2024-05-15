import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class AndroidNotificationChannelInfo {
  final String id;
  final String title;
  final String? description;
  final bool playSound;
  final String sound;
  final bool enableVibration;
  final Int64List? vibrationPattern;

  AndroidNotificationChannelInfo({
    required this.id,
    required this.title,
    required this.playSound,
    required this.sound,
    required this.enableVibration,
    this.vibrationPattern,
    this.description,
  });
}

class LocalNotification {
  static LocalNotification instance = LocalNotification._();

  LocalNotification._();

  List<AndroidNotificationChannel>? _androidChannels;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize(
      {List<AndroidNotificationChannelInfo>? channels}) async {
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

  Future<void> showNotification({
    required int messageId,
    String? title,
    String? body,
    String? payload,
    String? channelId = 'I',
    String? icon,
    String? largeIcon,
    Color? color,
    String? sound,
    bool colorized = false,
  }) async {
    AndroidNotificationChannel? targetChannel;
    if (_androidChannels?.isNotEmpty ?? false) {
      if (channelId != null) {
        targetChannel = _androidChannels
            ?.firstWhereOrNull((channel) => channel.id == channelId);
      }
    } else {
      // Android 8.0 이상에 필요한 채널 세부정보가 포함됨
      targetChannel = AndroidNotificationChannel(
          'flutter_local_notification', 'flutter_local_notification', // title
          importance: Importance.high,
          enableLights: true,
          enableVibration: false,
          showBadge: true,
          sound: RawResourceAndroidNotificationSound(sound ?? 'default_sound'),
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
      color: color,
      icon: icon,
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
      messageId,
      title ?? 'scheduled title',
      body ?? 'scheduled body',
      notificationDetails,
    );
  }

  Future<void> cancelNotification(int messageId) async {
    await _plugin.cancel(messageId);
  }

  Future<void> zonedScheduleNotification({
    required int messageId,
    String? title,
    String? body,
    String? payload,
    String? channelId,
    String? channelName,
    String? channelDescription,
    String? icon,
    String? largeIcon,
    Color? color,
    String? sound,
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    int durationDay = 0,
    int durationHour = 0,
    int durationMin = 0,
    bool colorized = false,
  }) async {
    await _plugin.zonedSchedule(
        messageId,
        title ?? 'scheduled title',
        body ?? 'scheduled body',
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
        // tz.TZDateTime(tz.local, year, month, day, hour, minute).subtract(
        //     Duration(
        //         days: durationDay, hours: durationHour, minutes: durationMin)),
        NotificationDetails(
            android: AndroidNotificationDetails(
          channelId ?? 'your channel id',
          channelName ?? 'your channel name',
          channelDescription: channelDescription,
        )),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  Future<void> _configureAndroidChannels(
      List<AndroidNotificationChannelInfo> channelInfo) async {
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
              info.id, info.title,
              description: info.description,
              // description
              importance: Importance.high,
              enableLights: true,
              enableVibration: info.enableVibration,
              vibrationPattern: info.vibrationPattern,
              showBadge: true,
              sound: RawResourceAndroidNotificationSound(info.sound),
              playSound: info.playSound,
            ),
          );
        }
      },
    );
  }
}
