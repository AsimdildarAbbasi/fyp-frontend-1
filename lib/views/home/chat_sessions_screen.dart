import 'package:flutter/material.dart';
import 'package:fyp_flutter/views/components/constants.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/side_menu_controller.dart';
import '../../controllers/voice_controller.dart';
import '../../models/message.dart';
import '../../models/voice_response.dart';
import '../../services/chat_service.dart';
import '../components/message_bubble.dart';
import '../components/side_menu.dart';
import '../components/voice_input_bar.dart';
import '../profile_view.dart';

class ChatSessionsScreen extends StatefulWidget {
  const ChatSessionsScreen({super.key});

  @override
  State<ChatSessionsScreen> createState() => _ChatSessionsScreenState();
}

class _ChatSessionsScreenState extends State<ChatSessionsScreen> {
  bool showMenu = false;
  final RxnInt activeSessionId = RxnInt(null);
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;

  final ScrollController _scrollController = ScrollController();
  final VoiceController _voiceController = Get.put(VoiceController());

  @override
  void initState() {
    super.initState();

    // Sync session IDs safely between controller and screen
    ever(activeSessionId, (int? id) {
      if (_voiceController.sessionId.value != id) {
        _voiceController.sessionId.value = id;
      }
    });

    ever(_voiceController.sessionId, (int? id) {
      if (activeSessionId.value != id) {
        activeSessionId.value = id;
      }
    });

    // Listen for completed voice stream responses
    ever(_voiceController.newVoiceResponse, (VoiceResponse? response) {
      if (response != null) {
        _appendNewMessages(response);
      }
    });
  }

  void _appendNewMessages(VoiceResponse response) {
    String userTextColor = "black";
    if (response.emotion == "CALM") {
      userTextColor = "green";
    } else if (response.emotion == "STRESSED") {
      userTextColor = "red";
    }

    final nowTime = DateFormat("hh:mm a").format(DateTime.now());

    // 1. ADD USER MESSAGE (With Audio URL)
    messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: response.userText,
        time: nowTime,
        isCurrentUser: true,
        textColor: userTextColor,
        audioUrl: response.userAudioUrl,
      ),
    );

    // 2. ADD BOT MESSAGE (With Audio URL)
    messages.add(
      ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: response.botText,
        time: nowTime,
        isCurrentUser: false,
        textColor: "black",
        audioUrl: response.botAudioUrl,
      ),
    );

    messages.refresh();
    _scrollToBottom();
  }

  Future<void> _loadMessages(int sessionId) async {
    try {
      final loadedMessages = await ChatService().fetchMessages(sessionId);
      messages.value = loadedMessages;
      _scrollToBottom();
    } catch (e) {
      debugPrint("Failed to load messages: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    // Secondary scroll after layout settlements
    Future.delayed(const Duration(milliseconds: 350), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startNewChat() async {
    final prefs = await SharedPreferences.getInstance();
    String studentId = prefs.getString('student_id') ?? "2023-ARID-0274";

    try {
      final newId = await ChatService().createNewSession(studentId);
      activeSessionId.value = newId;
      messages.clear();

      if (Get.isRegistered<SideMenuController>()) {
        Get.find<SideMenuController>().loadHistory();
      }
    } catch (e) {
      debugPrint("Failed to start new chat: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(),

              // Scrollable Chat Message List
              Expanded(
                child: Obx(() {
                  if (activeSessionId.value == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1C2D).withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: Color(0xFF245C94),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Start a new session with the Advisor",
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Tap the mic below to ask questions about your grades, courses, or advisor",
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        "No messages yet. Tap the microphone to speak.",
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16).copyWith(bottom: 24),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return MessageBubble(
                        message: msg,
                        bubbleWidth: screenSize.width * 0.75,
                        onPlayAudio: (msg.audioUrl != null && msg.audioUrl!.isNotEmpty)
                            ? () {
                                _voiceController.playBotAudio(msg.audioUrl!);
                              }
                            : null,
                      );
                    },
                  );
                }),
              ),

              // Floating Real-Time Streaming Text Overlay Card
              _buildStreamingOverlayCard(),

              // Bottom Voice Input Action Bar
              Container(
                decoration: BoxDecoration(
                  color: AppGradients.primaryLight,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: VoiceInputBar(sessionId: activeSessionId),
                ),
              ),
            ],
          ),

          // Side Menu Drawer Overlay Backdrop
          if (showMenu)
            GestureDetector(
              onTap: () {
                setState(() {
                  showMenu = false;
                });
              },
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),

          // Animated Side Menu
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: showMenu ? 0 : -screenSize.width * 0.78,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: screenSize.width * 0.78,
              child: SideMenu(
                onSessionSelected: (selectedId) {
                  if (selectedId != null) {
                    activeSessionId.value = selectedId;
                    _loadMessages(selectedId);
                  } else {
                    _startNewChat();
                  }
                  setState(() {
                    showMenu = false;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingOverlayCard() {
    return Obx(() {
      final state = _voiceController.voiceState.value;
      final transcript = _voiceController.userTranscript.value;
      final streamingText = _voiceController.streamingReplyText.value;

      final bool hasStreamingContent = (state == VoiceChatState.generatingText ||
          state == VoiceChatState.preparingTts ||
          transcript.isNotEmpty ||
          streamingText.isNotEmpty);

      if (!hasStreamingContent) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Transcribed text rendered above the streaming box: "You: <transcription text>"
            if (transcript.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF245C94).withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.record_voice_over_outlined,
                        size: 15,
                        color: Color(0xFF245C94),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "You: $transcript",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B1C2D),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // 2. Floating text card streaming incoming response word-by-word/token-by-token
            if (streamingText.isNotEmpty || state == VoiceChatState.generatingText)
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.22,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B1C2D).withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1C2D),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.smart_toy_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Advisor is replying...",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B1C2D),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3B82F6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                "Live streaming",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: SingleChildScrollView(
                        reverse: true, // Auto-scroll to show latest incoming tokens
                        child: Text(
                          streamingText.isEmpty
                              ? "Advisor is preparing response..."
                              : streamingText,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: AppGradients.primaryLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () {
              setState(() {
                showMenu = true;
              });
            },
          ),
          const Text(
            "University AI Advisor",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          GestureDetector(
            onTap: () => Get.to(() => ProfileView()),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF0B1C2D),
              child: Icon(
                Icons.person_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}