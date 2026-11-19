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

// class MyStudents {
//   final String sid;
//   final double cgpa;
//   final String sos;

//   MyStudents({
//     required this.sid,
//     required this.cgpa,
//     required this.sos,
//   });

//   factory MyStudents.fromJson(Map<String, dynamic> json) {
//     return MyStudents(
//       sid: json['sid'] ?? '',
//       //cgpa: json['cgpa'] ?? 0.0,
//       cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0.0,
//       sos: json['sos'] ?? '',
//     );
//   }
// }




class MyStudents {
  final String sid;
  final double cgpa;
  final String sos;

  MyStudents({
    required this.sid,
    required this.cgpa,
    required this.sos,
  });

  factory MyStudents.fromJson(Map<String, dynamic> json) {
    return MyStudents(
      sid: json['sid']?.toString() ?? '',
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0.0,
      sos: json['sos']?.toString() ?? '',
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
