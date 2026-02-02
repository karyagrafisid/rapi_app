import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rab.dart';

class RabService {
  // Development URL (Emulator)
  static const String baseUrl = 'https://rapi.uiidalwa.web.id/api';

  // Production URL (Ganti dengan IP Computer atau Domain Hosting)
  // static const String baseUrl = 'http://192.168.1.XX:8000/api';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Future<List<Rab>> fetchRabs({int page = 1}) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/rabs?page=$page'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      List<dynamic> list;
      if (body is Map<String, dynamic> && body.containsKey('data')) {
        list = body['data'];
      } else {
        list = body;
      }
      List<Rab> rabs = list.map((dynamic item) => Rab.fromJson(item)).toList();
      return rabs;
    } else {
      throw Exception('Failed to load RABs');
    }
  }

  Future<Rab> getRabById(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/rabs/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Rab.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load RAB');
    }
  }

  Future<Rab> createRab(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/rabs'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return Rab.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create RAB');
    }
  }

  Future<Rab> updateRab(int id, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/rabs/$id'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Rab.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update RAB');
    }
  }

  Future<void> deleteRab(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/rabs/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete RAB');
    }
  }

  Future<void> createRabDetail(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/rab-details'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create RAB detail');
    }
  }

  Future<void> updateRabDetail(int id, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/rab-details/$id'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update RAB detail');
    }
  }

  Future<void> deleteRabDetail(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/rab-details/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete RAB detail: ${response.body}');
    }
  }

  Future<void> updateRabDetailWithFile(
    int id,
    Map<String, String> data,
    File? file,
  ) async {
    final headers = await _getHeaders();
    var request = http.MultipartRequest(
      'POST', // Use POST with _method=PUT for Laravel when sending files
      Uri.parse('$baseUrl/rab-details/$id'),
    );

    request.headers.addAll(headers);

    // Add fields
    request.fields.addAll(data);
    // Spoof PUT method
    request.fields['_method'] = 'PUT';

    // Add file
    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath('foto_nota', file.path),
      );
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      // Allow 201 too just in case
      if (response.statusCode != 201) {
        throw Exception('Failed to update RAB detail: ${response.body}');
      }
    }
  }

  Future<void> createAdditionalRabItems(
    int rabId,
    List<Map<String, dynamic>> items,
    File? notaFile,
  ) async {
    final headers = await _getHeaders();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/rab-details/additional'),
    );

    request.headers.addAll(headers);

    request.fields['id_rab'] = rabId.toString();

    for (int i = 0; i < items.length; i++) {
      request.fields['nama_item[$i]'] = items[i]['nama_item'];
      request.fields['volume[$i]'] = items[i]['volume'].toString();
      request.fields['satuan[$i]'] = items[i]['satuan'];
      request.fields['harga_satuan[$i]'] = items[i]['harga_satuan'].toString();
      request.fields['keterangan[$i]'] = items[i]['keterangan'] ?? '';
      request.fields['prioritas[$i]'] =
          items[i]['prioritas'] ?? 'Sangat Tinggi';

      if (items[i]['harga_beli'] != null) {
        request.fields['harga_beli[$i]'] = items[i]['harga_beli'].toString();
      }
      if (items[i]['tanggal_belanja'] != null) {
        request.fields['tanggal_belanja[$i]'] = items[i]['tanggal_belanja'];
      }
    }

    if (notaFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('nota', notaFile.path),
      );
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw Exception('Failed to create additional items: ${response.body}');
    }
  }
}
