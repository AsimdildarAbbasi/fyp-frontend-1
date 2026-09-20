import 'dart:typed_data';
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
}
