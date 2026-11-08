import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

enum VoiceChatState {
  idle,
  recording,
  uploading,
  processingStt,
  generatingText,
  preparingTts,
  completed,
}

class VoiceController extends GetxController {
  final ChatService _chatService = ChatService();
  final VoiceService _voiceService = VoiceService();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // State Management
  final Rx<VoiceChatState> voiceState = VoiceChatState.idle.obs;
  final RxBool isRecording = false.obs;
  final RxBool isUploading = false.obs;
  final RxInt secondsElapsed = 0.obs;

  // Real-time dynamic messages
  final RxString statusMessage = ''.obs;
  final RxString userTranscript = ''.obs;
  final RxString streamingReplyText = ''.obs;

  // Active chat session & completed voice responses
  final RxnInt sessionId = RxnInt();
  final Rxn<VoiceResponse> newVoiceResponse = Rxn<VoiceResponse>();

  // Audio Playback states
  final RxBool isPlayingAudio = false.obs;
  final RxString currentlyPlayingUrl = ''.obs;

  Timer? _timer;
  String? _audioFilePath;

  @override
  void onInit() {
    super.onInit();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      isPlayingAudio.value = (state == PlayerState.playing);
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        currentlyPlayingUrl.value = '';
      }
    });
  }

  @override
  void onClose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _stopTimer();
    super.onClose();
  }

  Future<void> toggleRecording() async {
    if (voiceState.value == VoiceChatState.recording) {
      await stopRecording();
    } else if (voiceState.value == VoiceChatState.idle) {
      await startRecording();
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    // Web handles permissions directly via browser getUserMedia in the recorder
    if (await _audioRecorder.hasPermission()) {
      return true;
    }

    if (kIsWeb) {
      Get.snackbar('Permission Denied', 'Microphone permission is required.');
      return false;
    }

    // Native platform permission check
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

      // Reset dynamic states
      userTranscript.value = '';
      streamingReplyText.value = '';
      statusMessage.value = '';
      secondsElapsed.value = 0;

      RecordConfig config;

      if (kIsWeb) {
        // Safe cross-browser web recording config
        if (await _audioRecorder.isEncoderSupported(AudioEncoder.aacLc)) {
          config = const RecordConfig(encoder: AudioEncoder.aacLc);
        } else if (await _audioRecorder.isEncoderSupported(AudioEncoder.opus)) {
          config = const RecordConfig(encoder: AudioEncoder.opus);
        } else {
          config = const RecordConfig(encoder: AudioEncoder.wav);
        }
        await _audioRecorder.start(config, path: '');
      } else {
        final dir = await getApplicationDocumentsDirectory();
        _audioFilePath = '${dir.path}/input_${DateTime.now().millisecondsSinceEpoch}.m4a';
        config = const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );
        await _audioRecorder.start(config, path: _audioFilePath!);
      }

      voiceState.value = VoiceChatState.recording;
      isRecording.value = true;
      _startTimer();
    } catch (e) {
      voiceState.value = VoiceChatState.idle;
      isRecording.value = false;
      Get.snackbar('Recording Error', 'Failed to start recording: $e');
      debugPrint("Start recording error: $e");
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _stopTimer();
      isRecording.value = false;

      // Stage: UPLOADING
      voiceState.value = VoiceChatState.uploading;
      isUploading.value = true;
      statusMessage.value = "Uploading voice...";

      if (path != null) {
        _audioFilePath = path;
        Uint8List audioBytes;
        String fileName = "user_voice.m4a";
        String mimeType = "audio/m4a";

        if (kIsWeb) {
          // On Web, path is a blob URL
          final blobUri = Uri.parse(path);
          final blobResponse = await http.get(blobUri);
          audioBytes = blobResponse.bodyBytes;

          if (path.contains("wav")) {
            fileName = "user_voice.wav";
            mimeType = "audio/wav";
          } else if (path.contains("ogg")) {
            fileName = "user_voice.ogg";
            mimeType = "audio/ogg";
          } else {
            fileName = "user_voice.webm";
            mimeType = "audio/webm";
          }
        } else {
          final file = io.File(path);
          if (!await file.exists()) {
            throw Exception("Recorded file not found at $path");
          }
          audioBytes = await file.readAsBytes();
        }

        const capturedEmotion = "Neutral";
        await _streamVoiceMessage(
          audioBytes: audioBytes,
          fileName: fileName,
          mimeType: mimeType,
          emotion: capturedEmotion,
        );
      } else {
        voiceState.value = VoiceChatState.idle;
        isUploading.value = false;
        statusMessage.value = '';
        Get.snackbar('Error', 'Failed to save recording.');
      }
    } catch (e) {
      voiceState.value = VoiceChatState.idle;
      isRecording.value = false;
      isUploading.value = false;
      statusMessage.value = '';
      Get.snackbar('Recording Error', 'Failed to stop recording: $e');
      debugPrint("Stop recording error: $e");
    }
  }

  Future<void> _streamVoiceMessage({
    required Uint8List audioBytes,
    required String fileName,
    required String mimeType,
    required String emotion,
  }) async {
    try {
      int? activeId = sessionId.value;

      if (activeId == null) {
        final prefs = await SharedPreferences.getInstance();
        final studentId = prefs.getString('student_id');

        if (studentId == null || studentId.isEmpty) {
          Get.snackbar('Session Required', 'Please log in to start voice chat.');
          voiceState.value = VoiceChatState.idle;
          isUploading.value = false;
          statusMessage.value = '';
          return;
        }

        activeId = await _chatService.createNewSession(studentId);
        sessionId.value = activeId;

        if (Get.isRegistered<SideMenuController>()) {
          Get.find<SideMenuController>().loadHistory();
        }
      }

      final stream = _voiceService.uploadVoiceStream(
        sessionId: activeId,
        fileData: audioBytes,
        fileName: fileName,
        mimeType: mimeType,
        emotion: emotion,
      );

      bool completed = false;

      await for (final event in stream) {
        final type = event['type'] as String?;

        switch (type) {
          case 'status':
            final msg = (event['message'] ?? '').toString();
            statusMessage.value = msg;
            if (msg.contains('Preparing your voice') ||
                msg.contains('Understanding your voice')) {
              // Stage: PROCESSING_STT
              voiceState.value = VoiceChatState.processingStt;
            } else if (msg.contains('Preparing the audio reply')) {
              // Stage: PREPARING_TTS
              voiceState.value = VoiceChatState.preparingTts;
            }
            break;

          case 'transcript':
            // Render transcribed text above floating box
            userTranscript.value = (event['text'] ?? '').toString();
            voiceState.value = VoiceChatState.generatingText;
            statusMessage.value = "Advisor is replying...";
            break;

          case 'reply_start':
            // Stage: GENERATING_TEXT
            voiceState.value = VoiceChatState.generatingText;
            statusMessage.value = "Advisor is replying...";
            streamingReplyText.value = '';
            break;

          case 'token':
            // Stream token by token
            voiceState.value = VoiceChatState.generatingText;
            statusMessage.value = "Advisor is replying...";
            final token = (event['text'] ?? '').toString();
            streamingReplyText.value += token;
            break;

          case 'reply_complete':
            final completeText = (event['text'] ?? '').toString();
            if (completeText.isNotEmpty) {
              streamingReplyText.value = completeText;
            }
            // Stage: PREPARING_TTS
            voiceState.value = VoiceChatState.preparingTts;
            statusMessage.value = "Preparing the audio reply...";
            break;

          case 'complete':
            completed = true;
            final data = event['data'] as Map<String, dynamic>? ?? {};
            final finalUserText =
                (data['user_text'] ?? userTranscript.value).toString();
            final finalBotText =
                (data['bot_text'] ?? streamingReplyText.value).toString();
            final userAudioUrl = (data['user_audio_url'] ?? '').toString();
            final botAudioUrl = (data['bot_audio_url'] ?? '').toString();
            final userEmotion = (data['user_emotion'] ?? emotion).toString();

            // Stage: COMPLETED
            voiceState.value = VoiceChatState.completed;

            final response = VoiceResponse(
              userText: finalUserText,
              botText: finalBotText,
              userAudioUrl: userAudioUrl,
              botAudioUrl: botAudioUrl,
              emotion: userEmotion,
              detectedLanguage: data['detected_language']?.toString(),
              responseLanguage: data['response_language']?.toString(),
            );

            // Notify ChatScreen to append message pair to main chat list
            newVoiceResponse.value = response;

            // Automatically play bot audio reply
            if (botAudioUrl.isNotEmpty) {
              playBotAudio(botAudioUrl);
            }

            // Brief transition delay before clearing bottom floating card
            await Future.delayed(const Duration(milliseconds: 350));
            userTranscript.value = '';
            streamingReplyText.value = '';
            statusMessage.value = '';
            isUploading.value = false;
            voiceState.value = VoiceChatState.idle;
            break;

          case 'error':
            completed = true;
            final errorMsg =
                (event['message'] ?? 'Voice processing failed.').toString();
            Get.snackbar('Voice Error', errorMsg);
            voiceState.value = VoiceChatState.idle;
            isUploading.value = false;
            statusMessage.value = '';
            userTranscript.value = '';
            streamingReplyText.value = '';
            break;
        }
      }

      if (!completed && voiceState.value != VoiceChatState.idle) {
        voiceState.value = VoiceChatState.idle;
        isUploading.value = false;
        statusMessage.value = '';
      }
    } catch (e) {
      Get.snackbar('Stream Error', 'Could not process voice: $e');
      debugPrint("Voice stream processing error: $e");
      voiceState.value = VoiceChatState.idle;
      isUploading.value = false;
      statusMessage.value = '';
      userTranscript.value = '';
      streamingReplyText.value = '';
    }
  }

  Future<void> sendTextMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (voiceState.value != VoiceChatState.idle) return;

    try {
      int? activeId = sessionId.value;

      if (activeId == null) {
        final prefs = await SharedPreferences.getInstance();
        final studentId = prefs.getString('student_id');

        if (studentId == null || studentId.isEmpty) {
          Get.snackbar('Session Required', 'Please log in to send a message.');
          return;
        }

        activeId = await _chatService.createNewSession(studentId);
        sessionId.value = activeId;

        if (Get.isRegistered<SideMenuController>()) {
          Get.find<SideMenuController>().loadHistory();
        }
      }

      userTranscript.value = trimmed;
      streamingReplyText.value = '';
      voiceState.value = VoiceChatState.generatingText;
      statusMessage.value = "Advisor is replying...";

      final response = await _chatService.sendTextMessage(
        activeId,
        trimmed,
        emotion: "Neutral",
      );

      voiceState.value = VoiceChatState.completed;
      newVoiceResponse.value = response;

      if (response.botAudioUrl.isNotEmpty) {
        playBotAudio(response.botAudioUrl);
      }

      await Future.delayed(const Duration(milliseconds: 350));
      userTranscript.value = '';
      streamingReplyText.value = '';
      statusMessage.value = '';
      voiceState.value = VoiceChatState.idle;
    } catch (e) {
      Get.snackbar('Chat Error', 'Could not send message: $e');
      debugPrint("Send text message error: $e");
      voiceState.value = VoiceChatState.idle;
      statusMessage.value = '';
      userTranscript.value = '';
      streamingReplyText.value = '';
    }
  }

  void playBotAudio(String path) async {
    try {
      if (path.isEmpty) return;
      final fullURLString = resolveAudioUrl(path);

      if (isPlayingAudio.value && currentlyPlayingUrl.value == fullURLString) {
        await _audioPlayer.stop();
        isPlayingAudio.value = false;
        currentlyPlayingUrl.value = '';
        return;
      }

      await _audioPlayer.stop();
      currentlyPlayingUrl.value = fullURLString;
      await _audioPlayer.play(UrlSource(fullURLString));
    } catch (e) {
      Get.snackbar('Playback Error', 'Failed to play audio.');
      debugPrint("Audio playback error: $e");
    }
  }

  String resolveAudioUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final base = NetworkManager.baseURL;
    final domain =
        base.endsWith('/api') ? base.substring(0, base.length - 4) : base;

    if (cleanPath.startsWith('/api/')) {
      return '$domain$cleanPath';
    }
    return '$domain/api$cleanPath';
  }

  void _startTimer() {
    secondsElapsed.value = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsElapsed.value++;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
}