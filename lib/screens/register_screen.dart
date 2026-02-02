import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rapi_app/screens/home_screen.dart';
import 'package:rapi_app/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

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
        duration: isError
            ? const Duration(seconds: 5)
            : const Duration(seconds: 1),
      ),
    );
  }

  void _register() async {
    if (_nameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _positionController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showCustomSnackBar('Semua field harus diisi', isError: true);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showCustomSnackBar('Konfirmasi password tidak cocok', isError: true);
      return;
    }

    if (_passwordController.text.length < 6) {
      _showCustomSnackBar('Password minimal 6 karakter', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.register(
        namaLengkap: _nameController.text,
        username: _usernameController.text,
        jabatan: _positionController.text,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (mounted) {
        _showCustomSnackBar('Pendaftaran Berhasil!');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
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
                'Daftar Akun Baru',
                style: GoogleFonts.instrumentSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B1546),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lengkapi data untuk bergabung',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Form
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Nama Lengkap'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan nama lengkap',
                      prefixIcon: Icon(Icons.badge_outlined),
                      fillColor: Color(0xFFF5F6F8),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Username'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan username',
                      prefixIcon: Icon(Icons.person_outline),
                      fillColor: Color(0xFFF5F6F8),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Jabatan / Posisi'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _positionController,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Bendahara, Admin',
                      prefixIcon: Icon(Icons.work_outline),
                      fillColor: Color(0xFFF5F6F8),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Password'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Minimal 6 karakter',
                      prefixIcon: const Icon(Icons.lock_outline),
                      fillColor: const Color(0xFFF5F6F8),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Konfirmasi Password'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: 'Ulangi password',
                      prefixIcon: const Icon(Icons.lock_reset),
                      fillColor: const Color(0xFFF5F6F8),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
                        child: const Text('Daftar Sekarang'),
                      ),
                    ),

              const SizedBox(height: 24),
              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sudah Punya Akun? ',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Masuk Saja',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF0B1546),
      ),
    );
  }
}
