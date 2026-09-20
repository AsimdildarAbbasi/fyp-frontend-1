import 'package:flutter/material.dart';
import 'package:fyp_flutter/views/components/constants.dart';
import 'package:get/get.dart';
import '../../controllers/voice_controller.dart';

class VoiceInputBar extends StatelessWidget {
  final RxnInt sessionId;

  VoiceInputBar({super.key, required this.sessionId});

  final VoiceController controller = Get.put(VoiceController());

  @override
  Widget build(BuildContext context) {
    // Sync the local active session ID with the controller's session ID
    //ever(sessionId, (int? id) => controller.sessionId.value = id);
   // ever(controller.sessionId, (int? id) => sessionId.value = id);

    // return Container(
    //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    //   decoration: BoxDecoration(
    //     gradient: AppGradients.mainGradient,
    //     boxShadow: [
    //       BoxShadow(
    //         color: Colors.black.withOpacity(0.05),
    //         blurRadius: 10,
    //         offset: const Offset(0, -5),
    //       ),
    //     ],
    //   ),
    //   child: SafeArea(
    //     top: false,
    //     child: Row(
    //       children: [
    //         Expanded(
    //           child: Obx(() {
    //             if (controller.isUploading.value) {
    //               return const Center(child: CircularProgressIndicator());
    //             } else if (controller.isRecording.value) {
    //               return Text(
    //                 "Recording... ${controller.secondsElapsed.value}s",
    //                 style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
    //               );
    //             } else {
    //               return const Text(
    //                 "Tap to speak...",
    //                 style: TextStyle(color: Colors.grey, fontSize: 16),
    //               );
    //             }
    //           }),
    //         ),
    //         Obx(() => GestureDetector(
    //               onTap: () => controller.toggleRecording(),
    //               child: Container(
    //                 padding: const EdgeInsets.all(16),
    //                 decoration: BoxDecoration(
    //                   color: controller.isRecording.value ? Colors.red : const Color(0xFF3B82F6),
    //                   shape: BoxShape.circle,
    //                   boxShadow: [
    //                     BoxShadow(
    //                       color: (controller.isRecording.value ? Colors.red : const Color(0xFF3B82F6)).withOpacity(0.4),
    //                       blurRadius: 8,
    //                       offset: const Offset(0, 4),
    //                     ),
    //                   ],
    //                 ),
    //                 child: Icon(
    //                   controller.isRecording.value ? Icons.stop : Icons.mic,
    //                   color: Colors.white,
    //                   size: 28,
    //                 ),
    //               ),
    //             )),
    //       ],
    //     ),
    //   ),
    // );

    return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppGradients.mainGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 🧠 Left Icon
              const Icon(Icons.psychology, color: Colors.white70),

              // 🎤 Center Mic Button
              Obx(() => GestureDetector(
                onTap: () => controller.toggleRecording(),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    controller.isRecording.value ? Icons.stop : Icons.mic,
                    color: Colors.black87,
                    size: 28,
                  ),
                ),
              )),

              // 📊 Right placeholder (balance spacing)
              const SizedBox(width: 24),
            ],
          ),
        ),
    );
  }
}
