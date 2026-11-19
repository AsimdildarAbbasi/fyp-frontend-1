import 'package:flutter/material.dart';
import 'package:fyp_flutter/views/components/constants.dart';
import 'package:get/get.dart';
import '../../controllers/eeg_controller.dart';
import '../../controllers/voice_controller.dart';

class VoiceInputBar extends StatefulWidget {
  final RxnInt sessionId;

  const VoiceInputBar({super.key, required this.sessionId});

  @override
  State<VoiceInputBar> createState() => _VoiceInputBarState();
}

class _VoiceInputBarState extends State<VoiceInputBar> {
  final VoiceController controller = Get.find<VoiceController>();
  final EegController eegController = Get.put(EegController());

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = _textController.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() {
        _hasText = has;
      });
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    setState(() {
      _hasText = false;
    });
    _focusNode.unfocus();
    controller.sendTextMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🚀 Main Input Capsule Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              gradient: AppGradients.mainGradient,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // 🧠 Left Circular Button: EEG Muse 2 Connection & Status
                GestureDetector(
                  onTap: () => eegController.toggleConnection(
                    activeSessionId: widget.sessionId.value,
                  ),
                  child: Obx(() {
                    final isStreaming = eegController.isConnectedOrStreaming;
                    final isConnecting = eegController.isConnecting;

                    Color iconColor = const Color(0xFFF59E0B); // Warm amber sunburst accent default
                    IconData iconData = Icons.auto_awesome;

                    if (isStreaming) {
                      iconColor = const Color(0xFF10B981); // Bright Green when connected & streaming
                      iconData = Icons.psychology;
                    } else if (isConnecting) {
                      iconColor = Colors.amber;
                      iconData = Icons.hourglass_top_rounded;
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: isStreaming
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Tooltip(
                        message: eegController.statusMessage.value.isNotEmpty
                            ? eegController.statusMessage.value
                            : "Muse 2 EEG Connection",
                        child: Icon(
                          iconData,
                          color: iconColor,
                          size: 22,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(width: 8),

                // 💬 Center White Input Capsule
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Obx(() {
                      final isRec = (controller.voiceState.value == VoiceChatState.recording);
                      final isBusy = (controller.voiceState.value != VoiceChatState.idle && !isRec);

                      if (isRec) {
                        final secs = controller.secondsElapsed.value;
                        final minsStr = (secs ~/ 60).toString().padLeft(2, '0');
                        final secsStr = (secs % 60).toString().padLeft(2, '0');

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Recording audio ($minsStr:$secsStr)...",
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        enabled: !isBusy,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSendText(),
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Ask advisor or type message...",
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(width: 8),

                // 🎤 / 🚀 Right Circular Button (Blue Mic / Red Stop / Send Button)
                Obx(() {
                  final state = controller.voiceState.value;
                  final isRec = (state == VoiceChatState.recording);
                  final isBusy = (state != VoiceChatState.idle && !isRec);

                  VoidCallback? action;
                  Widget iconWidget;
                  Color bgColor;

                  if (isRec) {
                    // Recording -> Red Stop Square
                    action = () => controller.toggleRecording();
                    bgColor = const Color(0xFFEF4444);
                    iconWidget = const Icon(
                      Icons.stop_rounded,
                      color: Colors.white,
                      size: 24,
                    );
                  } else if (_hasText) {
                    // Typing text -> Send Button
                    action = isBusy ? null : _handleSendText;
                    bgColor = Colors.white.withOpacity(0.24);
                    iconWidget = const Icon(
                      Icons.send_rounded,
                      color: Color(0xFF38BDF8),
                      size: 21,
                    );
                  } else {
                    // Idle -> Blue Microphone
                    action = isBusy ? null : () => controller.toggleRecording();
                    bgColor = Colors.white.withOpacity(0.24);
                    iconWidget = Icon(
                      isBusy ? Icons.hourglass_empty_rounded : Icons.mic_rounded,
                      color: const Color(0xFF38BDF8),
                      size: 24,
                    );
                  }

                  return GestureDetector(
                    onTap: action,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        boxShadow: isRec
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(child: iconWidget),
                    ),
                  );
                }),
              ],
            ),
          ),

          // ⏳ Left-aligned status message matching UI: [spinner] Advisor is thinking...
          Obx(() {
            final state = controller.voiceState.value;
            final status = controller.statusMessage.value;
            final showStatus = (state != VoiceChatState.idle &&
                state != VoiceChatState.recording &&
                status.isNotEmpty);

            if (!showStatus) {
              return const SizedBox(height: 4);
            }

            final displayText = status.isNotEmpty ? status : "Advisor is thinking...";

            return Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2, left: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF334155)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    displayText,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
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
