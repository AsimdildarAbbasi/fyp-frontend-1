import 'package:flutter/material.dart';
import 'package:fyp_flutter/views/components/constants.dart';
import '../../models/message.dart';

// class MessageBubble extends StatelessWidget {
//   final ChatMessage message;
//   final double bubbleWidth;
//
//   const MessageBubble({
//     super.key,
//     required this.message,
//     required this.bubbleWidth,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: message.isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//         children: [
//           if (!message.isCurrentUser) ...[
//             const CircleAvatar(
//               radius: 16,
//               backgroundColor: Color(0xFF1E293B),
//               child: Icon(Icons.smart_toy, size: 20, color: Colors.white),
//             ),
//             const SizedBox(width: 8),
//           ],
//           Container(
//             constraints: BoxConstraints(maxWidth: bubbleWidth),
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: message.isCurrentUser ? message.actualColor.withOpacity(0.9) : Colors.white,
//               borderRadius: BorderRadius.only(
//                 topLeft: const Radius.circular(16),
//                 topRight: const Radius.circular(16),
//                 bottomLeft: Radius.circular(message.isCurrentUser ? 16 : 0),
//                 bottomRight: Radius.circular(message.isCurrentUser ? 0 : 16),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 5,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   message.text,
//                   style: TextStyle(
//                     color: message.isCurrentUser ? Colors.white : Colors.black87,
//                     fontSize: 15,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   message.time,
//                   style: TextStyle(
//                     color: message.isCurrentUser ? Colors.white70 : Colors.black54,
//                     fontSize: 10,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (message.isCurrentUser) const SizedBox(width: 24),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import '../../models/message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final double bubbleWidth;
  final VoidCallback? onPlayAudio; // <--- NEW: Callback for playing audio

  const MessageBubble({
    super.key,
    required this.message,
    required this.bubbleWidth,
    this.onPlayAudio, // <--- NEW: Pass this from your ChatSessionsScreen
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isCurrentUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF1E293B),
              child: Icon(Icons.smart_toy, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(maxWidth: bubbleWidth),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: message.isCurrentUser ? AppGradients.mainGradient:LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
              Colors.white,
              Colors.white54,
              ],
              ),
              //color: message.isCurrentUser ? message.actualColor.withOpacity(0.9) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(message.isCurrentUser ? 16 : 0),
                bottomRight: Radius.circular(message.isCurrentUser ? 0 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: message.isCurrentUser ? message.actualColor : Colors.black87,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),

                // NEW: Row containing the speaker icon and the time
                Row(
                  //mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Only show the speaker if an onPlayAudio function is provided

                      InkWell(
                        onTap: onPlayAudio,
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 18,
                          // Adjust color based on whether it's user or bot bubble
                          color: message.isCurrentUser ? Colors.white : const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 6),

                    Text(
                      message.time,
                      style: TextStyle(
                        color: message.isCurrentUser ? Colors.white70 : Colors.black54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (message.isCurrentUser) const SizedBox(width: 24),
        ],
      ),
    );
  }
}