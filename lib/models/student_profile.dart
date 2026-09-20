class StudentProfile {
  final String name;
  final String registrationNo;
  final double cgpa;
  final String semester;
  final String sectionCode;
  final String advisorName;
  final String advisorDesignation;

  StudentProfile({
    required this.name,
    required this.registrationNo,
    required this.cgpa,
    required this.semester,
    required this.sectionCode,
    required this.advisorName,
    required this.advisorDesignation,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      name: json['name'] ?? '',
      registrationNo: json['registration_no'] ?? '',
      cgpa: (json['cgpa'] as num?)?.toDouble() ?? 0.0,
      semester: json['semester'] ?? '',
      sectionCode: json['section_code'] ?? '',
      advisorName: json['advisor_name'] ?? '',
      advisorDesignation: json['advisor_designation'] ?? '',
    );
  }
}
