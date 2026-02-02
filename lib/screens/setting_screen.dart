import 'package:flutter/material.dart';
import 'package:rapi_app/screens/login_screen.dart';
import 'package:rapi_app/screens/settings/about_screen.dart';
import 'package:rapi_app/screens/settings/help_center_screen.dart';
import 'package:rapi_app/screens/settings/notification_screen.dart';
import 'package:rapi_app/screens/settings/profile_screen.dart';
import 'package:rapi_app/screens/settings/security_screen.dart';
import 'package:rapi_app/services/auth_service.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Setting',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSettingItem(
            context,
            Icons.person_outline,
            'Profil Saya',
            const ProfileScreen(),
          ),
          _buildSettingItem(
            context,
            Icons.lock_outline,
            'Keamanan',
            const SecurityScreen(),
          ),
          _buildSettingItem(
            context,
            Icons.notifications_none,
            'Notifikasi',
            const NotificationScreen(),
          ),
          const Divider(height: 40),
          _buildSettingItem(
            context,
            Icons.help_outline,
            'Pusat Bantuan',
            const HelpCenterScreen(),
          ),
          _buildSettingItem(
            context,
            Icons.info_outline,
            'Tentang Aplikasi',
            const AboutScreen(),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF0B1546), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }
}
