// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../controllers/voice_controller.dart';
// import '../../models/message.dart';
// import '../../models/voice_response.dart';
// import '../../services/chat_service.dart';
// import '../components/message_bubble.dart';
// import '../components/side_menu.dart';
// import '../components/voice_input_bar.dart';
// import '../profile_view.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class ChatSessionsScreen extends StatefulWidget {
//   const ChatSessionsScreen({super.key});
//
//   @override
//   State<ChatSessionsScreen> createState() => _ChatSessionsScreenState();
// }
//
// class _ChatSessionsScreenState extends State<ChatSessionsScreen> {
//   bool showMenu = false;
//   final RxnInt activeSessionId = RxnInt(null);
//   var messages = <ChatMessage>[].obs;
//
//   final ScrollController _scrollController = ScrollController();
//   final VoiceController _voiceController = Get.put(VoiceController());
//
//   @override
//   void initState() {
//     super.initState();
//     ever(activeSessionId, (int? id) {
//       if (id != null) {
//         _loadMessages(id);
//       } else {
//         messages.clear();
//       }
//     });
//
//     ever(_voiceController.newVoiceResponse, (VoiceResponse? response) {
//       if (response != null) {
//         _appendNewMessages(response);
//       }
//     });
//   }
//
//   void _appendNewMessages(VoiceResponse response) {
//     // Map the emotion to a color, just like you did in ChatService
//     String userTextColor = "black";
//     if (response.emotion == "CALM") {
//       userTextColor = "green";
//     } else if (response.emotion == "STRESSED") {
//       userTextColor = "red";
//     }
//
//     messages.add(
//         ChatMessage(
//           id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
//           text: response.userText,
//           time: "Now", // Temporary time placeholder
//           isCurrentUser: true,
//           textColor: userTextColor,
//         )
//     );
//
//     messages.add(
//         ChatMessage(
//           id: (DateTime.now().millisecondsSinceEpoch + 1).toString(), // Temporary ID
//           text: response.botText,
//           time: "Now",
//           isCurrentUser: false,
//           textColor: "black",
//         )
//     );
//
//     // Scroll to the bottom to show the new messages
//     _scrollToBottom();
//
//
//   }
//
//   Future<void> _loadMessages(int sessionId) async {
//     try {
//       final loadedMessages = await ChatService().fetchMessages(sessionId);
//       messages.value = loadedMessages;
//       _scrollToBottom();
//     } catch (e) {
//       print("Failed to load messages: $e");
//     }
//   }
//
//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }
//
//   Future<void> _startNewChat() async {
//     final prefs = await SharedPreferences.getInstance();
//     final studentId = prefs.getString('student_id');
//     if (studentId == null) return;
//
//     try {
//       final newId = await ChatService().createNewSession(studentId);
//       activeSessionId.value = newId;
//       messages.clear();
//     } catch (e) {
//       print("Failed to start new chat: $e");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF1F5F9), // Light background
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               _buildAppBar(),
//               Expanded(
//                 child: Obx(() {
//                   if (activeSessionId.value == null) {
//                     return const Center(
//                       child: Text(
//                         "Start a new session with the Advisor",
//                         style: TextStyle(color: Colors.grey, fontSize: 16),
//                       ),
//                     );
//                   }
//
//                   return ListView.builder(
//                     controller: _scrollController,
//                     padding: const EdgeInsets.all(16).copyWith(bottom: 20),
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       return MessageBubble(
//                         message: messages[index],
//                         bubbleWidth: MediaQuery.of(context).size.width * 0.75,
//                       );
//                     },
//                   );
//                 }),
//               ),
//               VoiceInputBar(sessionId: activeSessionId),
//             ],
//           ),
//
//           if (showMenu)
//             GestureDetector(
//               onTap: () {
//                 setState(() {
//                   showMenu = false;
//                 });
//               },
//               child: Container(
//                 color: Colors.black.withOpacity(0.3),
//               ),
//             ),
//
//           AnimatedPositioned(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeInOut,
//             left: showMenu ? 0 : -MediaQuery.of(context).size.width * 0.75,
//             top: 0,
//             bottom: 0,
//             child: SizedBox(
//               width: MediaQuery.of(context).size.width * 0.75,
//               child: SideMenu(
//                 onSessionSelected: (selectedId) {
//                   if (selectedId != null) {
//                     activeSessionId.value = selectedId;
//                   } else {
//                     _startNewChat();
//                   }
//                   setState(() {
//                     showMenu = false;
//                   });
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAppBar() {
//     return Container(
//       padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 16, left: 16, right: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           IconButton(
//             icon: const Icon(Icons.menu, color: Colors.black87),
//             onPressed: () {
//               setState(() {
//                 showMenu = true;
//               });
//             },
//           ),
//           const Text(
//             "University AI Advisor",
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           GestureDetector(
//             onTap: () => Get.to(() => ProfileView()),
//             child: const CircleAvatar(
//               radius: 18,
//               backgroundColor: Color(0xFFEFF6FF),
//               child: Icon(Icons.person, color: Color(0xFF3B82F6)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:fyp_flutter/views/components/constants.dart';
import 'package:get/get.dart';
import '../../controllers/side_menu_controller.dart';
import '../../controllers/voice_controller.dart';
import '../../models/message.dart';
import '../../models/voice_response.dart';
import '../../services/chat_service.dart';
import '../components/message_bubble.dart';
import '../components/side_menu.dart';
import '../components/voice_input_bar.dart';
import '../profile_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatSessionsScreen extends StatefulWidget {
  const ChatSessionsScreen({super.key});

  @override
  State<ChatSessionsScreen> createState() => _ChatSessionsScreenState();
}

class _ChatSessionsScreenState extends State<ChatSessionsScreen> {
  bool showMenu = false;
  final RxnInt activeSessionId = RxnInt(null);
  var messages = <ChatMessage>[].obs;

  final ScrollController _scrollController = ScrollController();
  final VoiceController _voiceController = Get.put(VoiceController());

  // @override
  // void initState() {
  //   super.initState();
  //   ever(activeSessionId, (int? id) {
  //     if (id != null) {
  //       _loadMessages(id);
  //     } else {
  //       messages.clear();
  //     }
  //   });
  //
  //   ever(_voiceController.newVoiceResponse, (VoiceResponse? response) {
  //     if (response != null) {
  //       _appendNewMessages(response);
  //     }
  //   });
  // }
  @override
  void initState() {
    super.initState();

    // 1. Sync session IDs safely here instead of in the VoiceInputBar build method
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

    // 2. REMOVED the ever(activeSessionId) that was causing the race condition.

    ever(_voiceController.newVoiceResponse, (VoiceResponse? response) {
      if (response != null) {
        _appendNewMessages(response);
        messages.refresh(); // Force UI update after appending
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

    // 1. ADD USER MESSAGE (With Audio URL)
    messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: response.userText,
          time: "Now",
          isCurrentUser: true,
          textColor: userTextColor,
          audioUrl: response.userAudioUrl, // <--- Added audioUrl
        )
    );

    // 2. ADD BOT MESSAGE (With Audio URL)
    messages.add(
        ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: response.botText,
          time: "Now",
          isCurrentUser: false,
          textColor: "black",
          audioUrl: response.botAudioUrl, // <--- Added audioUrl
        )
    );

    _scrollToBottom();
  }

  Future<void> _loadMessages(int sessionId) async {
    try {
      final loadedMessages = await ChatService().fetchMessages(sessionId);
      messages.value = loadedMessages;
      _scrollToBottom();
    } catch (e) {
      print("Failed to load messages: $e");
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
  }

  // Future<void> _startNewChat() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final studentId = prefs.getString('student_id');
  //   if (studentId == null) return;
  //
  //   try {
  //     final newId = await ChatService().createNewSession(studentId);
  //     activeSessionId.value = newId;
  //     messages.clear();
  //   } catch (e) {
  //     print("Failed to start new chat: $e");
  //   }
  // }
  Future<void> _startNewChat() async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('student_id');
    if (studentId == null) return;

    try {
      final newId = await ChatService().createNewSession(studentId);
      activeSessionId.value = newId;
      messages.clear();

      // Refresh the side menu history
      if (Get.isRegistered<SideMenuController>()) {
        Get.find<SideMenuController>().loadHistory();
      }
    } catch (e) {
      print("Failed to start new chat: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Obx(() {
                  if (activeSessionId.value == null) {
                    return const Center(
                      child: Text(
                        "Start a new session with the Advisor",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16).copyWith(bottom: 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];

                      return MessageBubble(
                        message: msg,
                        bubbleWidth: MediaQuery.of(context).size.width * 0.75,
                        // 3. PASS THE PLAYBACK FUNCTION TO THE BUBBLE
                        onPlayAudio: (msg.audioUrl != null && msg.audioUrl!.isNotEmpty)
                            ? () {
                          _voiceController.playBotAudio(msg.audioUrl!);
                        }
                            : null, // If null, the speaker icon won't show
                      );
                    },
                  );
                }),
              ),
              Container(
                  decoration: BoxDecoration(
                    color: AppGradients.primaryLight,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                child:VoiceInputBar(sessionId: activeSessionId),
              )

            ],
          ),

          if (showMenu)
            GestureDetector(
              onTap: () {
                setState(() {
                  showMenu = false;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: showMenu ? 0 : -MediaQuery.of(context).size.width * 0.75,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
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

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppGradients.primaryLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 10),
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
              child: Icon(Icons.person_outlined,color: Colors.white,),
            ),
          ),
        ],
      ),
    );
  }
}