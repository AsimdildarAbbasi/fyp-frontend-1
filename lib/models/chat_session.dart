class ChatSession {
  final int id;
  final String title;
  final String startTime;

  ChatSession({
    required this.id,
    required this.title,
    required this.startTime,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['session_id'] ?? 0,
      title: json['title'] ?? '',
      startTime: json['start_time'] ?? '',
    );
  }
}
