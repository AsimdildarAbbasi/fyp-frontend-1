import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NetworkManager {
  //static const String baseURL = "http://10.166.36.83:8000/api";
  //static const String baseURL = "http://192.168.100.181:8000/api";//home
  static const String defaultBaseURL = "http://192.168.100.181:8000/api";//hotspot
  static String _currentBaseURL = defaultBaseURL;

  static final ValueNotifier<String> baseURLNotifier = ValueNotifier<String>(_currentBaseURL);

  static String get baseURL => _currentBaseURL;

  static const String _prefKey = 'custom_base_url';

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _currentBaseURL = formatBaseUrl(saved);
        baseURLNotifier.value = _currentBaseURL;
      }
    } catch (_) {}
  }

  static Future<void> setBaseURL(String newUrl) async {
    final formatted = formatBaseUrl(newUrl);
    _currentBaseURL = formatted;
    baseURLNotifier.value = formatted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, formatted);
    } catch (_) {}
  }

  static Future<void> resetToDefault() async {
    _currentBaseURL = defaultBaseURL;
    baseURLNotifier.value = defaultBaseURL;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (_) {}
  }

  static String get displayHost {
    try {
      final uri = Uri.parse(_currentBaseURL);
      if (uri.hasPort) {
        return '${uri.host}:${uri.port}';
      }
      return uri.host.isNotEmpty ? uri.host : _currentBaseURL;
    } catch (_) {
      return _currentBaseURL;
    }
  }

  static String formatBaseUrl(String input) {
    var text = input.trim().replaceAll(' ', '');
    if (text.isEmpty) {
      return defaultBaseURL;
    }

    if (!text.startsWith('http://') && !text.startsWith('https://')) {
      text = 'http://$text';
    }

    try {
      final uri = Uri.parse(text);
      final scheme = uri.scheme.isNotEmpty ? uri.scheme : 'http';
      final host = uri.host.isNotEmpty
          ? uri.host
          : text.replaceFirst(RegExp(r'https?://'), '').split(':').first.split('/').first;
      final port = uri.hasPort ? uri.port : 8000;

      var path = uri.path.trim();
      while (path.endsWith('/')) {
        path = path.substring(0, path.length - 1);
      }
      if (path.isEmpty) {
        path = '/api';
      } else if (!path.endsWith('/api')) {
        path = '$path/api';
      }

      return '$scheme://$host:$port$path';
    } catch (_) {
      while (text.endsWith('/')) {
        text = text.substring(0, text.length - 1);
      }
      if (!text.endsWith('/api')) {
        text = '$text/api';
      }
      return text;
    }
  }

  static Future<Map<String, dynamic>> testConnection([String? testUrl]) async {
    final target = formatBaseUrl(testUrl ?? baseURL);
    try {
      final uri = Uri.parse(target);
      final testUrls = [
        Uri.parse('${uri.scheme}://${uri.host}:${uri.port}/'),
        Uri.parse('${uri.scheme}://${uri.host}:${uri.port}/docs'),
        Uri.parse(target),
      ];

      for (final u in testUrls) {
        try {
          final response = await http.get(u).timeout(const Duration(seconds: 3));
          if (response.statusCode >= 200 && response.statusCode < 500) {
            return {
              'success': true,
              'message': 'Connected successfully! (HTTP ${response.statusCode})',
            };
          }
        } catch (_) {}
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
    return {
      'success': false,
      'message': 'Cannot reach server at $target. Make sure backend is running and phone is on same Wi-Fi.',
    };
  }


  Future<dynamic> request(String url, String method, {Map<String, dynamic>? body}) async {
    final fullUrl = Uri.parse(baseURL + url);
    http.Response response;

    final headers = {
      "Content-Type": "application/json",
    };

    switch (method.toUpperCase()) {
      case 'POST':
        response = await http.post(
          fullUrl,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          fullUrl,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(
          fullUrl,
          headers: headers,
        );
        break;
      case 'GET':
      default:
        response = await http.get(
          fullUrl,
          headers: headers,
        );
        break;
    }

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      return jsonDecode(response.body);
    } else {
      String detail = "Server error occurred";
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey("detail")) {
          detail = errorData["detail"].toString();
        }
      } catch (_) {}
      throw Exception(detail);
    }
  }

  Future<dynamic> uploadFile(
      String url,
      List<int> fileData,
      String fileName, {
        String mimeType = "audio/wav",
        Map<String, String>? parameters,
      }) async {
    final fullUrl = Uri.parse(baseURL + url);
    var request = http.MultipartRequest('POST', fullUrl);

    // Add the emotion parameter
    if (parameters != null) {
      request.fields.addAll(parameters);
    }

    // Parse the mimeType (e.g., "audio" and "wav")
    final mimeParts = mimeType.split('/');
    final primaryType = mimeParts.isNotEmpty ? mimeParts[0] : 'audio';
    final subType = mimeParts.length > 1 ? mimeParts[1] : 'wav';

    // Add the audio file with the explicit Content-Type header
    request.files.add(
      http.MultipartFile.fromBytes(
        'audio_file', // Matches your FastAPI 'audio_file' parameter
        fileData,
        filename: fileName,
        contentType: http.MediaType(primaryType, subType), // <--- THIS FIXES THE 400 ERROR
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      return jsonDecode(response.body);
    } else {
      String detail = "Server error occurred";
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey("detail")) {
          detail = errorData["detail"].toString();
        }
      } catch (_) {}
      throw Exception(detail);
    }
  }

  Stream<Map<String, dynamic>> uploadFileStream(
    String url,
    List<int> fileData,
    String fileName, {
    String mimeType = "audio/wav",
    Map<String, String>? parameters,
  }) async* {
    final fullUrl = Uri.parse(baseURL + url);
    var request = http.MultipartRequest('POST', fullUrl);

    if (parameters != null) {
      request.fields.addAll(parameters);
    }

    final mimeParts = mimeType.split('/');
    final primaryType = mimeParts.isNotEmpty ? mimeParts[0] : 'audio';
    final subType = mimeParts.length > 1 ? mimeParts[1] : 'wav';

    request.files.add(
      http.MultipartFile.fromBytes(
        'audio_file',
        fileData,
        filename: fileName,
        contentType: http.MediaType(primaryType, subType),
      ),
    );

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode < 200 || streamedResponse.statusCode > 299) {
      final responseBody = await streamedResponse.stream.bytesToString();
      String detail = "Server error occurred (${streamedResponse.statusCode})";
      try {
        final errorData = jsonDecode(responseBody);
        if (errorData is Map && errorData.containsKey("detail")) {
          detail = errorData["detail"].toString();
        }
      } catch (_) {}
      throw Exception(detail);
    }

    final lines = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          yield decoded;
        }
      } catch (e) {
        print("Failed to decode stream line: $trimmed, error: $e");
      }
    }
  }
}

