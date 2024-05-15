import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_notification_demo/home_screen.dart';
import 'package:local_notification_demo/local_notification.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  final localNotification = LocalNotification.instance;
  WidgetsFlutterBinding.ensureInitialized();
  localNotification.initialize(
    channels: [
      AndroidNotificationChannelInfo(
        id: 'I',
        title: '일반 알림',
        playSound: true,
        sound: 'default_sound',
        enableVibration: false,
      ),
    ],
  );
  _configureLocalTimeZone();
  runApp(const MyApp());
}

Future<void> _configureLocalTimeZone() async {
  if (kIsWeb || Platform.isLinux) {
    return;
  }
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}
