import 'package:flutter/material.dart';
import 'package:rapi_app/screens/settings/biometric_setup_screen.dart';
import 'package:rapi_app/services/auth_service.dart';
import 'package:rapi_app/screens/settings/change_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  Map<String, dynamic>? _userData;
  final AuthService _authService = AuthService();
  bool _isSmartLoginEnabled = false;
  String _smartLoginType = 'face'; // 'face' or 'fingerprint'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await _authService.getUser();

    setState(() {
      _userData = user;
      _isSmartLoginEnabled = prefs.getBool('smart_login_enabled') ?? false;
      _smartLoginType = prefs.getString('smart_login_type') ?? 'face';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smart_login_enabled', _isSmartLoginEnabled);
    await prefs.setString('smart_login_type', _smartLoginType);
  }

  @override
  Widget build(BuildContext context) {
    bool hasFaceId = _userData != null && _userData!['face_id'] != null;
    bool hasFingerprint =
        _userData != null && _userData!['fingerprint_id'] != null;
    bool canEnableSmartLogin = hasFaceId || hasFingerprint;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Keamanan',
          style: TextStyle(
            color: Color(0xFF0B1546),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF0B1546),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionTitle('Keamanan Login'),
                const SizedBox(height: 10),
                _buildSettingsCard([
                  _buildNavigationTile(
                    title: 'Ganti Password',
                    icon: Icons.lock_reset,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                _buildSectionTitle('Data Biometrik'),
                const SizedBox(height: 10),
                _buildSettingsCard([
                  _buildNavigationTile(
                    title: 'Atur Face ID',
                    icon: Icons.face,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const BiometricSetupScreen(type: 'face'),
                        ),
                      );
                      _loadSettings(); // Reload to update UI
                    },
                  ),
                  const Divider(height: 1),
                  _buildNavigationTile(
                    title: 'Atur Fingerprint ID',
                    icon: Icons.fingerprint,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const BiometricSetupScreen(type: 'fingerprint'),
                        ),
                      );
                      _loadSettings(); // Reload to update UI
                    },
                  ),
                ]),
                const SizedBox(height: 20),

                _buildSectionTitle('Smart Login'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Aktifkan Smart Login',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B1546),
                          ),
                        ),
                        subtitle: Text(
                          canEnableSmartLogin
                              ? 'Login cepat menggunakan biometrik'
                              : 'Atur data biometrik terlebih dahulu',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        value: canEnableSmartLogin && _isSmartLoginEnabled,
                        activeColor: const Color(0xFF0B1546),
                        onChanged: canEnableSmartLogin
                            ? (value) {
                                setState(() {
                                  _isSmartLoginEnabled = value;
                                });
                                _saveSettings();
                              }
                            : null,
                      ),
                      if (canEnableSmartLogin && _isSmartLoginEnabled) ...[
                        if (hasFaceId) ...[
                          const Divider(height: 1),
                          _buildRadioOption(
                            title: 'Face ID',
                            value: 'face',
                            icon: Icons.face,
                          ),
                        ],
                        if (hasFingerprint) ...[
                          const Divider(height: 1),
                          _buildRadioOption(
                            title: 'Fingerprint ID',
                            value: 'fingerprint',
                            icon: Icons.fingerprint,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Catatan: Pastikan perangkat Anda mendukung fitur biometrik yang dipilih.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF0B1546), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF0B1546),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0B1546),
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _smartLoginType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _smartLoginType = value;
        });
        _saveSettings();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0B1546) : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isSelected ? const Color(0xFF0B1546) : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF0B1546),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
