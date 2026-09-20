import '../models/student_profile.dart';
import '../network/network_manager.dart';

class ProfileService {
  final NetworkManager _network = NetworkManager();

  Future<StudentProfile> fetchProfile(String studentId) async {
    final data = await _network.request('/student/$studentId/profile', 'GET');
    return StudentProfile.fromJson(data);
  }
}
