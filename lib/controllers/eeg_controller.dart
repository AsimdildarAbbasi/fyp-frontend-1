import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/eeg_ble_service.dart';
import '../services/eeg_stream_service.dart';

enum EegStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  streaming,
  error,
}

class EegController extends GetxController {
  final EegBleService _bleService = EegBleService();
  final EegStreamService _streamService = EegStreamService();

  final Rx<EegStatus> status = EegStatus.disconnected.obs;
  final RxString deviceName = "".obs;
  final RxString currentEmotion = "Neutral".obs;
  final RxString statusMessage = "Tap to connect Muse 2".obs;
  final RxInt samplesCount = 0.obs;

  StreamSubscription? _bleSampleSub;
  StreamSubscription? _emotionSub;

  bool get isConnectedOrStreaming =>
      status.value == EegStatus.connected || status.value == EegStatus.streaming;

  bool get isConnecting =>
      status.value == EegStatus.scanning || status.value == EegStatus.connecting;

  @override
  void onInit() {
    super.onInit();
    // Listen for real-time backend emotion inference updates
    _emotionSub = _streamService.emotionStream.listen((emotion) {
      currentEmotion.value = emotion;
      debugPrint("🧠 EEG Real-Time Emotion Update: $emotion");
    });
  }

  @override
  void onClose() {
    disconnect();
    _bleService.dispose();
    _streamService.dispose();
    _emotionSub?.cancel();
    super.onClose();
  }

  /// Toggle connection when clicking the Brain icon on Voice bar.
  Future<void> toggleConnection({int? activeSessionId}) async {
    if (isConnectedOrStreaming || isConnecting) {
      await disconnect();
    } else {
      await connectAndStream(activeSessionId: activeSessionId);
    }
  }

  /// Scan, connect to Muse 2, and start real-time data streaming.
  Future<void> connectAndStream({int? activeSessionId}) async {
    try {
      status.value = EegStatus.scanning;
      statusMessage.value = "Scanning for Muse 2...";
      Get.snackbar(
        "Muse 2 Connection",
        "Scanning for nearby Muse headband. Make sure it is turned on.",
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );

      final device = await _bleService.findMuseDevice();
      if (device == null) {
        status.value = EegStatus.error;
        statusMessage.value = "Muse headband not found";
        Get.snackbar(
          "Muse 2 Not Found",
          "Could not find any Muse device nearby. Please ensure it is powered on and within range.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
        status.value = EegStatus.disconnected;
        return;
      }

      deviceName.value = device.platformName.isNotEmpty ? device.platformName : "Muse 2";
      status.value = EegStatus.connecting;
      statusMessage.value = "Connecting to ${deviceName.value}...";

      await _bleService.connect(device);

      // Connect to backend stream
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getString('student_id');

      try {
        await _streamService.connectWebSocket(
          studentId: studentId,
          sessionId: activeSessionId,
        );
      } catch (wsErr) {
        debugPrint("Warning: Backend stream connection deferred: $wsErr");
      }

      status.value = EegStatus.streaming;
      statusMessage.value = "Streaming EEG (${deviceName.value})";

      // Listen to raw BLE samples and feed into stream service
      _bleSampleSub?.cancel();
      _bleSampleSub = _bleService.sampleStream.listen((sample) {
        samplesCount.value++;
        _streamService.addSample(sample);
      });

      Get.snackbar(
        "Muse 2 Connected! 🧠",
        "Streaming live EEG data. Real-time emotion detection active.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint("EEG Connection Error: $e");
      status.value = EegStatus.error;
      statusMessage.value = "Connection failed: $e";
      Get.snackbar(
        "Connection Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      await disconnect();
    }
  }

  /// Disconnect Muse 2 headband and stop streaming.
  Future<void> disconnect() async {
    await _bleSampleSub?.cancel();
    _bleSampleSub = null;

    await _bleService.disconnect();
    await _streamService.disconnect();

    status.value = EegStatus.disconnected;
    statusMessage.value = "Tap to connect Muse 2";
    deviceName.value = "";
    samplesCount.value = 0;

    Get.snackbar(
      "Muse 2 Disconnected",
      "EEG stream stopped.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.grey.shade800,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}
