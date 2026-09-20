import 'package:flutter/material.dart';

class VoiceResponse {
  final String userText;
  final String botText;
  final String userAudioUrl;
  final String botAudioUrl;
  final String emotion;

  VoiceResponse({
    required this.userText,
    required this.botText,
    required this.userAudioUrl,
    required this.botAudioUrl,
    required this.emotion,
  });

  factory VoiceResponse.fromJson(Map<String, dynamic> json) {
    return VoiceResponse(
      userText: json['user_text'] ?? '',
      botText: json['bot_text'] ?? '',
      userAudioUrl: json['user_audio_url'] ?? '',
      botAudioUrl: json['bot_audio_url'] ?? '',
      emotion: json['user_emotion'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is VoiceResponse &&
              runtimeType == other.runtimeType &&
              userText == other.userText &&
              botText == other.botText &&
              userAudioUrl == other.userAudioUrl &&
              botAudioUrl == other.botAudioUrl &&
              emotion == other.emotion;

  @override
  int get hashCode =>
      userText.hashCode ^
      botText.hashCode ^
      userAudioUrl.hashCode ^
      botAudioUrl.hashCode ^
      emotion.hashCode;
}

enum Emotion {
  neutral,
  calm,
  stressed,
}

extension EmotionExtension on Emotion {
  String get value {
    switch (this) {
      case Emotion.neutral:
        return "Neutral";
      case Emotion.calm:
        return "CALM";
      case Emotion.stressed:
        return "STRESSED";
    }
  }

  static Emotion fromString(String val) {
    switch (val) {
      case "Neutral":
        return Emotion.neutral;
      case "CALM":
        return Emotion.calm;
      case "STRESSED":
        return Emotion.stressed;
      default:
        return Emotion.neutral;
    }
  }
}

Color getColorForEmotion(String emotionString) {
  final emotion = EmotionExtension.fromString(emotionString);
  switch (emotion) {
    case Emotion.neutral:
      return Colors.black;
    case Emotion.calm:
      return Colors.green;
    default:
      return Colors.red;
  }
}