import '../models/academic_reports.dart';
import '../network/network_manager.dart';

class AcademicService {
  final NetworkManager _network = NetworkManager();

  Future<List<OfferedCourse>> fetchOfferedCourses(String studentId) async {
    final data = await _network.request('/student/$studentId/offered-courses', 'GET');
    return (data as List).map((e) => OfferedCourse.fromJson(e)).toList();
  }

  Future<List<DroppedCourse>> fetchDroppedCourses(String studentId) async {
    final data = await _network.request('/student/$studentId/dropped-courses', 'GET');
    return (data as List).map((e) => DroppedCourse.fromJson(e)).toList();
  }

  Future<List<TranscriptCourse>> fetchTranscript(String studentId) async {
    final data = await _network.request('/student/$studentId/transcript', 'GET');
    return (data as List).map((e) => TranscriptCourse.fromJson(e)).toList();
  }
}
