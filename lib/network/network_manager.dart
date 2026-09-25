import 'dart:convert';
import 'package:http/http.dart' as http;

class NetworkManager {
  //static const String baseURL = "http://10.156.120.215:8000/api";
  // static const String baseURL = "http:// 192.168.100.6/8000/api";
  static const String baseURL = "http://127.0.0.1:8000/api";

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

