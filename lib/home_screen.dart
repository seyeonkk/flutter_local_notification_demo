import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_notification_demo/local_notification.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    LocalNotification.instance.requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Local Notification'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Column(
              children: [
                PaddedElevatedButton(
                  buttonText: 'Show notification',
                  onPressed: () async {
                    final params =
                        NotificationParams(messageId: 0, channelId: 'I');
                    await LocalNotification.instance.showNotification(params);
                  },
                ),
                if (kIsWeb || !Platform.isLinux) ...[
                  PaddedElevatedButton(
                    buttonText: 'Schedule notification to appear in 10 seconds '
                        'based on local time zone',
                    onPressed: () async {
                      final params = ScheduledNotificationParams(
                        messageId: 1,
                        channelId: 'I',
                        year: 2024,
                        month: 5,
                        day: 16,
                        hour: 21,
                        minute: 15,
                      );
                      await LocalNotification.instance
                          .zonedScheduleNotification(params);
                    },
                  ),
                ],
                PaddedElevatedButton(
                  buttonText: 'Cancel notification',
                  onPressed: () async {
                    await LocalNotification.instance.cancelNotification(1);
                  },
                ),
                PaddedElevatedButton(
                  buttonText: 'list notification',
                  onPressed: () async {
                    await LocalNotification.instance.getAndroidChannels();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaddedElevatedButton extends StatelessWidget {
  const PaddedElevatedButton({
    required this.buttonText,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(buttonText),
        ),
      );
}
