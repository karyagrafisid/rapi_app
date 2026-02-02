import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Development URL (Emulator)
  static const String baseUrl = 'https://rapi.uiidalwa.web.id/api';

  // Production URL (Ganti dengan IP Computer atau Domain Hosting)
  // static const String baseUrl = 'http://192.168.1.XX:8000/api';

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final user = data['user'];

      // Save token and user info
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_data', jsonEncode(user));

      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> register({
    required String namaLengkap,
    required String username,
    required String jabatan,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'nama_lengkap': namaLengkap,
        'username': username,
        'jabatan': jabatan,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final user = data['user'];

      // Save token and user info
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_data', jsonEncode(user));

      return data;
    } else {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Registration failed');
      } catch (e) {
        if (response.statusCode == 404) {
          throw Exception(
            'Endpoint /api/register tidak ditemukan di server (404). Silakan upload file api.php ke server.',
          );
        }
        throw Exception(
          'Server Error (${response.statusCode}): ${response.body}',
        );
      }
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      } catch (e) {
        // Ignore logout errors
      }
    }

    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> updateProfile(
    Map<String, String> data, {
    String? filePath,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Unauthenticated');

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/profile'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields.addAll(data);

    if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath('foto', filePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(result['user']));
    } else {
      throw Exception('Update profile failed: ${response.body}');
    }
  }

  Future<void> updateSecurity(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw Exception('Unauthenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/security'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      // Update local storage if user data returned
      final prefs = await SharedPreferences.getInstance();
      final currentUser = prefs.getString('user_data');
      if (currentUser != null) {
        // Merge updates if necessary, but backend returns user.
        await prefs.setString('user_data', jsonEncode(result['user']));
      }
    } else {
      throw Exception('Update security failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> loginViaSmartId(
    String smartId,
    String type,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login-smart'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'smart_id': smartId, 'type': type}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final user = data['user'];

      // Save token and user info
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_data', jsonEncode(user));

      return data;
    } else {
      throw Exception('Smart Login failed: ${response.body}');
    }
  }
}
