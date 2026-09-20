import 'package:intl/intl.dart';
import '../models/chat_session.dart';
import '../models/message.dart';
import '../network/network_manager.dart';

// class ChatService {
//   final NetworkManager _network = NetworkManager();
//
//   Future<List<ChatSession>> fetchChatSessions(String studentId) async {
//     final data = await _network.request('/student/$studentId/chat-sessions', 'GET');
//     return (data as List).map((e) => ChatSession.fromJson(e)).toList();
//   }
//
//   Future<List<ChatMessage>> fetchMessages(int sessionId) async {
//     final data = await _network.request('/chat/$sessionId/messages', 'GET');
//     final apiMessages = (data as List).map((e) => APIChatMessage.fromJson(e)).toList();
//
//     final inputFormatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
//     final outputFormatter = DateFormat("hh:mm a");
//
//     List<ChatMessage> uiMessages = [];
//
//     for (var msg in apiMessages) {
//       final isUser = (msg.sender == "User");
//       final text = msg.messageText ?? "";
//       final emotion = msg.emotion;
//
//       String timeString = "";
//       if (msg.timestamp != null) {
//         try {
//           final cleanRaw = msg.timestamp!.split('.').first;
//           final date = inputFormatter.parse(cleanRaw);
//           timeString = outputFormatter.format(date);
//         } catch (e) {
//           // Fallback if parsing fails
//           timeString = msg.timestamp!;
//         }
//       }
//
//       String textColor = "black";
//       if (isUser) {
//         if (emotion == "Neutral") {
//           textColor = "black";
//         } else if (emotion == "CALM") {
//           textColor = "green";
//         } else {
//           textColor = "red";
//         }
//       }
//
//       final chatBubble = ChatMessage(
//         id: msg.messageId.toString(),
//         text: text,
//         time: timeString,
//         isCurrentUser: isUser,
//         textColor: textColor,
//       );
//
//       uiMessages.add(chatBubble);
//     }
//
//     return uiMessages;
//   }
//
//   Future<int> createNewSession(String studentId) async {
//     final requestBody = {
//       "student_id": studentId,
//       "title": "New Advisor Session",
//     };
//
//     final data = await _network.request('/chat-sessions', 'POST', body: requestBody);
//     return data['session_id'] as int;
//   }
// }
import 'package:intl/intl.dart';
import '../models/chat_session.dart';
import '../models/message.dart';
import '../network/network_manager.dart';

class ChatService {
  final NetworkManager _network = NetworkManager();

  Future<List<ChatSession>> fetchChatSessions(String studentId) async {
    final data = await _network.request('/student/$studentId/chat-sessions', 'GET');
    return (data as List).map((e) => ChatSession.fromJson(e)).toList();
  }

  Future<List<ChatMessage>> fetchMessages(int sessionId) async {
    final data = await _network.request('/chat/$sessionId/messages', 'GET');
    final apiMessages = (data as List).map((e) => APIChatMessage.fromJson(e)).toList();

    final inputFormatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
    final outputFormatter = DateFormat("hh:mm a");

    List<ChatMessage> uiMessages = [];

    for (var msg in apiMessages) {
      final isUser = (msg.sender == "User");
      final text = msg.messageText ?? "";
      final emotion = msg.emotion;

      String timeString = "";
      if (msg.timestamp != null) {
        try {
          final cleanRaw = msg.timestamp!.split('.').first;
          final date = inputFormatter.parse(cleanRaw);
          timeString = outputFormatter.format(date);
        } catch (e) {
          // Fallback if parsing fails
          timeString = msg.timestamp!;
        }
      }

      String textColor = "black";
      if (isUser) {
        if (emotion == "Neutral") {
          textColor = "black";
        } else if (emotion == "CALM") {
          textColor = "green";
        } else {
          textColor = "red";
        }
      }

      final chatBubble = ChatMessage(
        id: msg.messageId.toString(),
        text: text,
        time: timeString,
        isCurrentUser: isUser,
        textColor: textColor,
        audioUrl: msg.voiceFile, // <--- THIS IS THE MISSING LINE!
      );

      uiMessages.add(chatBubble);
    }

    return uiMessages;
  }

  Future<int> createNewSession(String studentId) async {
    final requestBody = {
      "student_id": studentId,
      "title": "New Advisor Session",
    };

    final data = await _network.request('/chat-sessions', 'POST', body: requestBody);
    return data['session_id'] as int;
  }
}