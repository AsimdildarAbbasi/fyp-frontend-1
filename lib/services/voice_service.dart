import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/voice_response.dart';
import '../network/network_manager.dart';

class VoiceService {
  final NetworkManager _network = NetworkManager();

  Future<VoiceResponse> uploadVoice(int sessionId, Uint8List fileData, String fileName, String emotion) async {
    final endpoint = "/$sessionId/voice";
    final additionalParameters = {
      "emotion": emotion,
    };

    final responseData = await _network.uploadFile(
      endpoint,
      fileData,
      fileName,
      parameters: additionalParameters,
    );

    return VoiceResponse.fromJson(responseData);
  }

  Stream<Map<String, dynamic>> uploadVoiceStream({
    required int sessionId,
    required Uint8List fileData,
    required String fileName,
    required String mimeType,
    required String emotion,
  }) async* {
    yield* _network.uploadFileStream(
      "/$sessionId/voice",
      fileData,
      fileName,
      mimeType: mimeType,
      parameters: {
        "emotion": emotion,
        "stream": "true",
      },
    );
  }

  /// Fetch list of available TTS voices configured on the backend server.
  Future<Map<String, dynamic>?> fetchAvailableVoices() async {
    try {
      final res = await _network.request("/voices", "GET");
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (e) {
      debugPrint("fetchAvailableVoices error: $e");
    }
    return null;
  }

  /// Synthesize a speech sample via backend and get its static audio URL and duration.
  Future<Map<String, dynamic>?> testVoice(String voice, {String? text}) async {
    try {
      final body = <String, dynamic>{
        "voice": voice,
      };
      if (text != null && text.trim().isNotEmpty) {
        body["text"] = text.trim();
      }
      final res = await _network.request("/voices/test", "POST", body: body);
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (e) {
      debugPrint("testVoice error for voice '$voice': $e");
    }
    return null;
  }

  /// Fetch the student's saved voice preference from the database via backend API.
  Future<String?> getStudentVoicePreference(String studentId) async {
    try {
      final res = await _network.request("/student/$studentId/voice-preference", "GET");
      if (res is Map && res.containsKey("preferred_voice")) {
        return res["preferred_voice"]?.toString();
      }
    } catch (e) {
      debugPrint("getStudentVoicePreference error: $e");
    }
    return null;
  }

  /// Save the student's voice preference to the database via backend API.
  Future<bool> updateStudentVoicePreference(String studentId, String preferredVoice) async {
    try {
      final res = await _network.request(
        "/student/$studentId/voice-preference",
        "PUT",
        body: {"preferred_voice": preferredVoice},
      );
      return res is Map && res["status"] == "success";
    } catch (e) {
      debugPrint("updateStudentVoicePreference error: $e");
      return false;
    }
  }
}

