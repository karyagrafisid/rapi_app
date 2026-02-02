import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:rapi_app/services/auth_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricSetupScreen extends StatefulWidget {
  final String type; // 'face' or 'fingerprint'

  const BiometricSetupScreen({super.key, required this.type});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  bool _isSuccess = false;
  String _errorMessage = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.type == 'face') {
      _initializeCamera();
    } else {
      _checkFingerprintSupport();
    }
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _errorMessage = 'Izin kamera ditolak';
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'Kamera Tidak Tersedia';
        });
        return;
      }

      // Prefer front camera
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Kamera Tidak Tersedia: $e';
        });
      }
    }
  }

  Future<void> _checkFingerprintSupport() async {
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();

    // On some emulators isDeviceSupported returns false but canCheck might be true for weak biometrics.
    // But requirement says "Fingerscan Tidak Tersedia Pada Perangkat Anda".

    if (!canCheckBiometrics || !isDeviceSupported) {
      setState(() {
        _errorMessage = 'Fingerscan Tidak Tersedia Pada Perangkat Anda';
      });
      return;
    }

    // Check specific available biometrics
    final availableBiometrics = await _localAuth.getAvailableBiometrics();
    // Assuming if list contains fingerprint or strong/weak, it's okay.
    // If we want to be strict about "Fingerprint":
    if (!availableBiometrics.contains(BiometricType.fingerprint) &&
        !availableBiometrics.contains(BiometricType.strong)) {
      // Some devices use 'strong' for fingerprint.
      // But let's assume if 'canCheckBiometrics' is true, we might have it.
      // However, providing the specific error message if specifically fingerprint is missing:
      // If generic check succeeded but no fingerprint hardware specifically detected?
      // We'll trust canCheckBiometrics for now or show error if authenticated fails immediately with "no hardware".
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startScanning() async {
    setState(() {
      _isScanning = true;
      _isSuccess = false;
      _errorMessage = '';
    });

    if (widget.type == 'face') {
      _handleFaceScan();
    } else {
      _handleFingerprintScan();
    }
  }

  Future<void> _handleFaceScan() async {
    if (!_isCameraInitialized) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Kamera Tidak Tersedia';
      });
      return;
    }

    _animationController.repeat(reverse: true);

    // Capture delay simulating processing
    await Future.delayed(const Duration(seconds: 3));

    // In a real app we might take a picture here:
    // final file = await _cameraController!.takePicture();

    _animationController.stop();

    // Save Mock ID (In real scenario, this would be derived from the image or external service)
    final mockId = 'FACE_ID_${DateTime.now().millisecondsSinceEpoch}';
    _saveBiometricId(mockId);
  }

  Future<void> _handleFingerprintScan() async {
    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Pindai sidik jari Anda untuk menyimpan data',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        final mockId = 'FINGER_ID_${DateTime.now().millisecondsSinceEpoch}';
        _saveBiometricId(mockId);
      } else {
        setState(() {
          _isScanning = false;
          _errorMessage = 'Autentikasi gagal atau dibatalkan';
        });
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Gagal memindai: ${e.toString()}';
      });
    }
  }

  void _saveBiometricId(String id) async {
    try {
      final key = widget.type == 'face' ? 'face_id' : 'fingerprint_id';
      await _authService.updateSecurity({key: id});

      // Save locally for Login Screen access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_smart_id', id);
      await prefs.setString('saved_smart_type', widget.type);

      if (mounted) {
        setState(() {
          _isSuccess = true;
          _isScanning = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.type == 'face' ? 'Face ID' : 'Fingerprint ID'} berhasil disimpan',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'Gagal menyimpan data ke server';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFace = widget.type == 'face';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          isFace ? 'Atur Face ID' : 'Atur Fingerprint',
          style: const TextStyle(
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: isFace ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: isFace ? BorderRadius.circular(20) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: isFace
                    ? BorderRadius.circular(20)
                    : BorderRadius.circular(125),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isFace && _isCameraInitialized)
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width:
                                _cameraController!.value.previewSize?.height ??
                                250,
                            height:
                                _cameraController!.value.previewSize?.width ??
                                250,
                            child: CameraPreview(_cameraController!),
                          ),
                        ),
                      )
                    else
                      Icon(
                        isFace ? Icons.face : Icons.fingerprint,
                        size: 100,
                        color: _isScanning
                            ? const Color(0xFF0B1546)
                            : (_isSuccess ? Colors.green : Colors.grey),
                      ),

                    if (_isScanning)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                shape: isFace
                                    ? BoxShape.rectangle
                                    : BoxShape.circle,
                                borderRadius: isFace
                                    ? BorderRadius.circular(20)
                                    : null,
                                border: Border.all(
                                  color: const Color(
                                    0xFF0B1546,
                                  ).withOpacity(_animationController.value),
                                  width: 4,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _isScanning
                  ? 'Memindai...'
                  : (_isSuccess
                        ? 'Berhasil!'
                        : 'Tekan tombol untuk mulai memindai'),
              style: TextStyle(
                fontSize: 16,
                color: _isSuccess ? Colors.green : const Color(0xFF0B1546),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            if (!_isScanning &&
                _errorMessage !=
                    'Fingerscan Tidak Tersedia Pada Perangkat Anda' &&
                _errorMessage != 'Kamera Tidak Tersedia')
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _startScanning,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B1546),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isSuccess ? 'Scan Ulang' : 'Mulai Scan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
