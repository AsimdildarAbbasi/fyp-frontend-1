import 'package:flutter/material.dart';

class ChatMessage {
  final String id;
  final String text;
  final String time;
  final bool isCurrentUser;
  final String textColor;
  final String? audioUrl;

  ChatMessage({
    required this.id,
    required this.text,
    required this.time,
    required this.isCurrentUser,
    required this.textColor,
    this.audioUrl,
  });

  Color get actualColor {
    switch (textColor.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'white':
        return Colors.white;
      default:
        return Colors.black; // Fallback color
    }
  }
}

class APIChatMessage {
  final int messageId;
  final String sender;
  final String? messageText;
  final String? timestamp;
  final String emotion;

  APIChatMessage({
    required this.messageId,
    required this.sender,
    this.messageText,
    this.timestamp,
    required this.emotion,
  });

  factory APIChatMessage.fromJson(Map<String, dynamic> json) {
    return APIChatMessage(
      messageId: json['message_id'] ?? 0,
      sender: json['sender'] ?? '',
      messageText: json['message_text'],
      timestamp: json['timestamp'],
      emotion: json['emotion'] ?? '',
    );
  }

  String? get voiceFile => null;
}
