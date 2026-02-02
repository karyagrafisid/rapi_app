import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _pushNotification = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SwitchListTile(
            title: const Text('Push Notification'),
            subtitle: const Text('Terima notifikasi dari aplikasi'),
            value: _pushNotification,
            onChanged: (val) => setState(() => _pushNotification = val),
            activeThumbColor: const Color(0xFF0B1546),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
