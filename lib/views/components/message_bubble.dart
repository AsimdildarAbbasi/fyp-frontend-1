import 'package:flutter/material.dart';
import 'package:fyp_flutter/views/components/constants.dart';
import '../../models/message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final double bubbleWidth;
  final VoidCallback? onPlayAudio;

  const MessageBubble({
    super.key,
    required this.message,
    required this.bubbleWidth,
    this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isCurrentUser;
    final bool hasAudio = onPlayAudio != null && message.audioUrl != null && message.audioUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF0B1C2D),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: bubbleWidth),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? AppGradients.mainGradient
                    : const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          Color(0xFFF8FAFC),
                        ],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
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
                      color: isUser ? message.actualColor : const Color(0xFF0F172A),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (hasAudio) ...[
                        InkWell(
                          onTap: onPlayAudio,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Icon(
                              Icons.volume_up_rounded,
                              size: 18,
                              color: isUser ? Colors.white70 : const Color(0xFF245C94),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        message.time,
                        style: TextStyle(
                          color: isUser ? Colors.white60 : Colors.black45,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 16),
        ],
      ),
    );
  }
}