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
    LocalNotification().requestPermissions();
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
                    await LocalNotification().showNotification(messageId: 0);
                  },
                ),
                if (kIsWeb || !Platform.isLinux)...[
                  PaddedElevatedButton(
                    buttonText:
                    'Schedule notification to appear in 5 seconds '
                        'based on local time zone',
                    onPressed: () async {
                      await LocalNotification().zonedScheduleNotification(messageId: 0);
                    },
                  ),
                ],
                PaddedElevatedButton(
                  buttonText: 'Cancel notification',
                  onPressed: () async {
                    await LocalNotification().cancelNotification(0);
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