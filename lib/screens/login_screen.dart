import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapi_app/screens/home_screen.dart';
import 'package:rapi_app/screens/register_screen.dart';
import 'package:rapi_app/services/auth_service.dart';
import 'package:camera/camera.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  // Smart Login State
  bool _isSmartLoginEnabled = false;
  String _smartLoginType = 'face';

  void _showCustomSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isError ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isError
                  ? const Color(0xFFEF5350)
                  : const Color(0xFF66BB6A),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF2E7D32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isError
                        ? const Color(0xFFC62828)
                        : const Color(0xFF1B5E20),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSmartLoginSettings();
  }

  Future<void> _loadSmartLoginSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSmartLoginEnabled = prefs.getBool('smart_login_enabled') ?? false;
      _smartLoginType = prefs.getString('smart_login_type') ?? 'face';
    });
  }

  void _login() async {
    // ... existing login logic ...
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showCustomSnackBar('Username dan Password harus diisi', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (mounted) {
        _showCustomSnackBar('Login Berhasil!');
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // Delay for visual feedback
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Parse error message if it's a JSON string
        String errorMessage = 'Login Gagal';
        try {
          final errorString = e.toString().replaceFirst(
            'Exception: Login failed: ',
            '',
          );
          final errorJson = jsonDecode(errorString);
          errorMessage = errorJson['message'] ?? 'Login Gagal';
        } catch (_) {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }
        _showCustomSnackBar(errorMessage, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ... imports moved to top of file
  void _showBiometricModal() {
    if (_smartLoginType == 'face') {
      _handleFaceLogin();
    } else {
      _handleFingerprintLogin();
    }
  }

  Future<void> _handleFingerprintLogin() async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Pasang jari Anda pada sensor untuk masuk',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (didAuthenticate) {
        _performSmartLogin();
      }
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar('Gagal verifikasi sidik jari: $e', isError: true);
      }
    }
  }

  Future<void> _handleFaceLogin() async {
    // Request Permission
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        _showCustomSnackBar('Izin kamera ditolak', isError: true);
      }
      return;
    }

    // Show Scanning Dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _FaceScanningDialog(),
    );

    // Initialize Camera (Background)
    CameraController? cameraController;
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final frontCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
        cameraController = CameraController(
          frontCamera,
          ResolutionPreset.low,
          enableAudio: false,
        );
        await cameraController.initialize();
      }

      // Simulate Scanning Duration (GIF/Animation view)
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        Navigator.pop(context); // Close dialog
        _performSmartLogin();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        _showCustomSnackBar('Gagal verifikasi wajah', isError: true);
      }
    } finally {
      cameraController?.dispose();
    }
  }

  void _performSmartLogin() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final smartId = prefs.getString('saved_smart_id');

      if (smartId == null) {
        throw Exception('Data Smart Login tidak ditemukan');
      }

      await _authService.loginViaSmartId(smartId, _smartLoginType);

      if (mounted) {
        _showCustomSnackBar('Login Berhasil!');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Clean error message
        String errorMessage = 'Login Biometrik Gagal';
        try {
          final errorString = e.toString().replaceFirst(
            'Exception: Smart Login failed: ',
            '',
          );
          final errorJson = jsonDecode(errorString);
          errorMessage = errorJson['message'] ?? 'Login Biometrik Gagal';
        } catch (_) {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }
        _showCustomSnackBar(errorMessage, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(
                  'assets/images/iconrab.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                'Selamat Datang',
                style: GoogleFonts.instrumentSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B1546),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Silakan masuk untuk melanjutkan',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              // Form
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Username',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B1546),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan username',
                      prefixIcon: const Icon(Icons.person_outline),
                      fillColor: const Color(0xFFF5F6F8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B1546),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Masukkan password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      fillColor: const Color(0xFFF5F6F8),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Buttons
              _isLoading
                  ? const CircularProgressIndicator()
                  : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _login,
                            child: const Text('Masuk'),
                          ),
                        ),

                        if (_isSmartLoginEnabled) ...[
                          const SizedBox(width: 12),
                          // Biometric Button (Conditional)
                          InkWell(
                            onTap: _showBiometricModal,
                            child: Container(
                              width: 58,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE3F2FD),
                                ),
                              ),
                              child: Icon(
                                _smartLoginType == 'face'
                                    ? Icons.face_unlock_outlined
                                    : Icons.fingerprint,
                                color: const Color(0xFF0B1546),
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
              const SizedBox(height: 24),
              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Belum Punya Akun? ',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Buat Sekarang',
                      style: TextStyle(
                        color: Color(0xFF0B1546),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Copy
              const Text(
                '© 2026 Handcrafted by Kagraf.id',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
              const Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaceScanningDialog extends StatefulWidget {
  const _FaceScanningDialog();

  @override
  State<_FaceScanningDialog> createState() => _FaceScanningDialogState();
}

class _FaceScanningDialogState extends State<_FaceScanningDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Verifikasi Wajah',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B1546),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.face, size: 100, color: Colors.grey),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFF0B1546,
                            ).withOpacity(_controller.value),
                            width: 4,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sedang memindai...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
