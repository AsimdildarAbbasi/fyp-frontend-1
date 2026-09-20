class OfferedCourse {
  final String courseId;
  final String title;
  final String session;
  final String teacherName;
  final String sectionCode;

  OfferedCourse({
    required this.courseId,
    required this.title,
    required this.session,
    required this.teacherName,
    required this.sectionCode,
  });

  factory OfferedCourse.fromJson(Map<String, dynamic> json) {
    return OfferedCourse(
      courseId: json['course_id'] ?? '',
      title: json['title'] ?? '',
      session: json['session'] ?? '',
      teacherName: json['teacher_name'] ?? '',
      sectionCode: json['section_code'] ?? '',
    );
  }
}

class DroppedCourse {
  final String courseId;
  final String title;
  final String session;
  final String teacherName;
  final String grade;

  DroppedCourse({
    required this.courseId,
    required this.title,
    required this.session,
    required this.teacherName,
    required this.grade,
  });

  factory DroppedCourse.fromJson(Map<String, dynamic> json) {
    return DroppedCourse(
      courseId: json['course_id'] ?? '',
      title: json['title'] ?? '',
      session: json['session'] ?? '',
      teacherName: json['teacher_name'] ?? '',
      grade: json['grade'] ?? '',
    );
  }
}

class TranscriptCourse {
  final String session;
  final String courseId;
  final String title;
  final String grade;
  final int creditHours;

  TranscriptCourse({
    required this.session,
    required this.courseId,
    required this.title,
    required this.grade,
    required this.creditHours,
  });

  factory TranscriptCourse.fromJson(Map<String, dynamic> json) {
    return TranscriptCourse(
      session: json['session'] ?? '',
      courseId: json['course_id'] ?? '',
      title: json['title'] ?? '',
      grade: json['grade'] ?? '',
      creditHours: json['credit_hours'] ?? 0,
    );
  }
}
