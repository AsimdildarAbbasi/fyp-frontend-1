import 'dart:convert';
import 'package:http/http.dart' as http;

class NetworkManager {
  static const String baseURL = "http://10.156.120.215:8000/api";
  // static const String baseURL = "http://10.19.62.23:8000/api";

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

  // Future<dynamic> uploadFile(
  //     String url,
  //     List<int> fileData,
  //     String fileName, {
  //       String mimeType = "video/mp4", // Defaulted to mp4 as requested
  //       Map<String, String>? parameters,
  //     }) async {
  //   // 1. Construct the URL (assuming baseURL is defined in your class)
  //   final fullUrl = Uri.parse(baseURL + url);
  //   var request = http.MultipartRequest('POST', fullUrl);
  //
  //   // 2. Add text parameters to the form body
  //   if (parameters != null) {
  //     request.fields.addAll(parameters);
  //   }
  //
  //   // 3. Dynamically split the mimeType (e.g., "video/mp4" -> "video" and "mp4")
  //   final mimeParts = mimeType.split('/');
  //   final primaryType = mimeParts.isNotEmpty ? mimeParts[0] : 'video';
  //   final subType = mimeParts.length > 1 ? mimeParts[1] : 'mp4';
  //
  //   // 4. Add the file with the explicit Content-Type
  //   request.files.add(
  //     http.MultipartFile.fromBytes(
  //       'audio_file', // Note: keep this as whatever key your backend expects (e.g., 'video_file' or 'file')
  //       fileData,
  //       filename: fileName,
  //       contentType: http.MediaType(primaryType, subType),
  //     ),
  //   );
  //
  //   // 5. Send the API request
  //   final streamedResponse = await request.send();
  //   final response = await http.Response.fromStream(streamedResponse);
  //
  //   // 6. Handle the Response
  //   if (response.statusCode >= 200 && response.statusCode <= 299) {
  //     // Returning parsed JSON (equivalent to returning Data in Swift and parsing it later)
  //     return jsonDecode(response.body);
  //   } else {
  //     // Error handling mimicking your Swift logic
  //     String detail = "Server error occurred";
  //     try {
  //       final errorData = jsonDecode(response.body);
  //       if (errorData is Map && errorData.containsKey("detail")) {
  //         detail = errorData["detail"].toString();
  //       }
  //     } catch (_) {
  //       // Fallback if the server didn't return JSON
  //       detail = "HTTP Error ${response.statusCode}: ${response.reasonPhrase}";
  //     }
  //     throw Exception(detail);
  //   }
  // }
}
