import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class LocalNotification {
  // 싱글톤 패턴을 사용하기 위한 private static 변수
  static final LocalNotification _instance = LocalNotification._();

  factory LocalNotification() {
    return _instance;
  }

  LocalNotification._();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    DarwinInitializationSettings initializationSettingsDarwin =
        const DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
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
    String? channelId,
    String? channelName,
    String? channelDescription,
    String? icon,
    String? largeIcon,
    Color? color,
    String? sound,
    bool colorized = false,
  }) async {
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channelId ?? 'your channel id',
      channelName ?? 'your channel name',
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      color: color,
      icon: icon,
    );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails();

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
    await _flutterLocalNotificationsPlugin.show(
      messageId,
      title ?? 'scheduled title',
      body ?? 'scheduled body',
      notificationDetails,
    );
  }

  Future<void> cancelNotification(int messageId) async {
    await _flutterLocalNotificationsPlugin.cancel(messageId);
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
    int? time,
    bool colorized = false,
  }) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
        messageId,
        title ?? 'scheduled title',
        body ?? 'scheduled body',
        tz.TZDateTime.now(tz.local).add(Duration(seconds: time ?? 5)),
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
}
