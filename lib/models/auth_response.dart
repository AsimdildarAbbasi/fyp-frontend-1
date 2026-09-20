class AuthResponse {
  final int userId;
  final String? studentId;
  final String name;
  final String role;
  final String message;

  AuthResponse({
    required this.userId,
    this.studentId,
    required this.name,
    required this.role,
    required this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['user_id'] ?? 0,
      studentId: json['student_id'],
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
