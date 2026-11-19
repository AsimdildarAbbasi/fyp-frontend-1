import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/eeg_packet.dart';
import '../network/network_manager.dart';

class EegStreamService {
  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  final StreamController<String> _emotionController =
      StreamController<String>.broadcast();

  Stream<String> get emotionStream => _emotionController.stream;

  final List<EegSample> _buffer = [];
  Timer? _flushTimer;

  bool get isStreaming => _channel != null;

  /// Connect to backend WebSocket for real-time EEG streaming.
  Future<void> connectWebSocket({String? studentId, int? sessionId}) async {
    await disconnect();

    final baseUri = Uri.parse(NetworkManager.baseURL);
    final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';

    // Construct WebSocket URL e.g. ws://192.168.0.116:8000/api/eeg/ws
    final queryParams = <String, String>{};
    if (studentId != null) queryParams['student_id'] = studentId;
    if (sessionId != null) queryParams['session_id'] = sessionId.toString();

    final wsUri = Uri(
      scheme: wsScheme,
      host: baseUri.host,
      port: baseUri.port,
      path: '/api/eeg/ws',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    debugPrint("Connecting to EEG WebSocket: $wsUri");

    try {
      _channel = WebSocketChannel.connect(wsUri);
      _channelSub = _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data.toString());
            if (json is Map && json.containsKey('emotion')) {
              _emotionController.add(json['emotion'].toString());
            }
          } catch (_) {}
        },
        onError: (err) {
          debugPrint("EEG WebSocket error: $err");
        },
        onDone: () {
          debugPrint("EEG WebSocket closed");
        },
      );

      // Start buffer flush timer every 250 milliseconds (~64 samples batch)
      _flushTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        _flushBuffer(studentId: studentId, sessionId: sessionId);
      });
    } catch (e) {
      debugPrint("Could not connect to EEG WebSocket: $e");
      rethrow;
    }
  }

  /// Add a newly decoded EEG sample to the streaming buffer.
  void addSample(EegSample sample) {
    _buffer.add(sample);
  }

  void _flushBuffer({String? studentId, int? sessionId}) {
    if (_channel == null || _buffer.isEmpty) return;

    final batch = EegBatch(
      studentId: studentId,
      sessionId: sessionId,
      samples: List<EegSample>.from(_buffer),
    );
    _buffer.clear();

    try {
      _channel!.sink.add(jsonEncode(batch.toJson()));
    } catch (e) {
      debugPrint("Failed to send EEG batch over WebSocket: $e");
    }
  }

  /// Disconnect and flush any remaining samples.
  Future<void> disconnect() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    _buffer.clear();

    if (_channelSub != null) {
      await _channelSub!.cancel();
      _channelSub = null;
    }
    if (_channel != null) {
      try {
        await _channel!.sink.close();
      } catch (_) {}
      _channel = null;
    }
  }

  void dispose() {
    disconnect();
    _emotionController.close();
  }
}
