import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:fyp_flutter/controllers/side_menu_controller.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/voice_response.dart';
import '../services/chat_service.dart';
import '../services/voice_service.dart';
import '../network/network_manager.dart';

class VoiceController extends GetxController {
  final ChatService _chatService = ChatService();
  final VoiceService _voiceService = VoiceService();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  var isRecording = false.obs;
  var secondsElapsed = 0.obs;
  var isUploading = false.obs;

  var sessionId = RxnInt();
  var newVoiceResponse = Rxn<VoiceResponse>();

  Timer? _timer;
  String? _audioFilePath;

  @override
  void onClose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _stopTimer();
    super.onClose();
  }

  Future<void> toggleRecording() async {
    if (isRecording.value) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    // Check if the record package already has permission
    if (await _audioRecorder.hasPermission()) {
      return true;
    }

    // Fallback to permission_handler to request or open settings
    var status = await Permission.microphone.request();

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      Get.snackbar(
        'Permission Required',
        'Please enable microphone access in your app settings.',
        duration: const Duration(seconds: 4),
      );
      await openAppSettings();
    } else {
      Get.snackbar('Permission Denied', 'Microphone permission is required.');
    }
    return false;
  }

  Future<void> startRecording() async {
    try {
      final hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) return;

      final dir = await getApplicationDocumentsDirectory();
      // Use a timestamp to prevent file lock/overwrite issues
      _audioFilePath = '${dir.path}/input_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Explicitly set the config to ensure cross-platform compatibility
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc, // Standard for .m4a
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _audioRecorder.start(config, path: _audioFilePath!);

      isRecording.value = true;
      _startTimer();
    } catch (e) {
      isRecording.value = false;
      Get.snackbar('Recording Error', 'Failed to start recording.');
      print("Start recording error: $e");
    }
  }

  Future<void> stopRecording() async {
    try {
      // ALWAYS use the path returned by stop()
      final path = await _audioRecorder.stop();
      isRecording.value = false;
      _stopTimer();

      if (path != null) {
        _audioFilePath = path;
        String capturedEmotion = "Neutral"; // Skipping MuseManager logic
        await uploadVoice(capturedEmotion);
      } else {
        Get.snackbar('Error', 'Failed to save recording.');
      }
    } catch (e) {
      isRecording.value = false;
      Get.snackbar('Recording Error', 'Failed to stop recording.');
      print("Stop recording error: $e");
    }
  }

  Future<void> uploadVoice(String emotion) async {
    if (_audioFilePath == null) return;

    final file = File(_audioFilePath!);
    if (!await file.exists()) {
      Get.snackbar('Error', 'Audio file could not be found.');
      return;
    }

    isUploading.value = true;

    try {
      final data = await file.readAsBytes();
      int? activeId = sessionId.value;

      if (activeId == null) {
        final prefs = await SharedPreferences.getInstance();
        final studentId = prefs.getString('student_id');

        if (studentId == null) {
          Get.snackbar('Session Error', 'No student ID found. Please log in again.');
          return;
        }

        activeId = await _chatService.createNewSession(studentId);
        sessionId.value = activeId;

        if (Get.isRegistered<SideMenuController>()) {
          Get.find<SideMenuController>().loadHistory();
        }
      }

      final response = await _voiceService.uploadVoice(
        activeId!,
        data,
        "user_voice.m4a",
        emotion,
      );

      newVoiceResponse.value = response;
      playBotAudio(response.botAudioUrl);

    } catch (e) {
      Get.snackbar('Upload Failed', 'Could not send the voice message.');
      print("Failed to upload voice: $e");
    } finally {
      // Ensure uploading state is reset even if an error occurs
      isUploading.value = false;
    }
  }

  void playBotAudio(String path) async {
    try {
      final fullURLString = NetworkManager.baseURL + path;
      await _audioPlayer.play(UrlSource(fullURLString));
    } catch (e) {
      Get.snackbar('Playback Error', 'Failed to play the response.');
      print("Audio playback error: $e");
    }
  }

  void _startTimer() {
    secondsElapsed.value = 0;
    _timer?.cancel(); // Cancel any existing timer to prevent overlapping
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsElapsed.value++;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
}