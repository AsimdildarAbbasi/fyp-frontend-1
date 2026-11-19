class ShowStudents {
  final String sid;
  final double cgpa;
  final String name;

  ShowStudents({
    required this.sid,
    required this.cgpa,
    required this.name,
  });

  factory ShowStudents.fromJson(Map<String, dynamic> json) {
    return ShowStudents(
      sid: json['sid']?.toString() ?? '',
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0.0,
      name: json['name']?.toString() ?? '',
    );
  }
}
