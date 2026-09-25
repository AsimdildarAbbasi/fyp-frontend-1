import 'package:flutter/material.dart';
import 'package:fyp_flutter/views/components/constants.dart';
import 'package:get/get.dart';
import '../../controllers/voice_controller.dart';

class VoiceInputBar extends StatelessWidget {
  final RxnInt sessionId;

  VoiceInputBar({super.key, required this.sessionId});

  final VoiceController controller = Get.find<VoiceController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppGradients.mainGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🧠 Left Status / Icon
                Obx(() {
                  if (controller.voiceState.value == VoiceChatState.recording) {
                    final secs = controller.secondsElapsed.value;
                    final minsStr = (secs ~/ 60).toString().padLeft(2, '0');
                    final secsStr = (secs % 60).toString().padLeft(2, '0');

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$minsStr:$secsStr",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    );
                  }

                  return const Icon(Icons.psychology, color: Colors.white70);
                }),

                // 🎤 Center Action Button (Mic / Red Square Stop)
                Obx(() {
                  final state = controller.voiceState.value;
                  final isRec = (state == VoiceChatState.recording);
                  final isBusy = (state != VoiceChatState.idle && !isRec);

                  return GestureDetector(
                    onTap: isBusy ? null : () => controller.toggleRecording(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isRec
                            ? const Color(0xFFEF4444)
                            : (isBusy ? Colors.white70 : Colors.white),
                        // Circular in IDLE, Red Square in RECORDING
                        borderRadius: isRec
                            ? BorderRadius.circular(12)
                            : BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: isRec
                                ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.2),
                            blurRadius: isRec ? 12 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: isRec
                          ? const Icon(
                              Icons.stop_rounded,
                              color: Colors.white,
                              size: 28,
                            )
                          : Icon(
                              isBusy ? Icons.hourglass_empty_rounded : Icons.mic,
                              color: const Color(0xFF0B1C2D),
                              size: 28,
                            ),
                    ),
                  );
                }),

                // 📊 Right status indicator / balance
                Obx(() {
                  if (controller.voiceState.value == VoiceChatState.recording) {
                    return const Text(
                      "Recording",
                      style: TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }
                  return const SizedBox(width: 24);
                }),
              ],
            ),
          ),

          // Dynamic status message with loading spinner below the bottom bar
          Obx(() {
            final state = controller.voiceState.value;
            final status = controller.statusMessage.value;
            final showStatus = (state != VoiceChatState.idle &&
                state != VoiceChatState.recording &&
                status.isNotEmpty);

            if (!showStatus) {
              return const SizedBox(height: 4);
            }

            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF245C94)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status,
                    style: const TextStyle(
                      color: Color(0xFF245C94),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
