import '../models/teacher_model.dart';
import '../network/network_manager.dart';

class Teacher_Service {
  final NetworkManager _network = NetworkManager();

  Future<List<ShowStudents>> fetchmystudents(int advisor_id) async {
    final data = await _network.request('/student/$advisor_id/ShowStudents', 'GET');
    return (data as List).map((e) => ShowStudents.fromJson(e)).toList();
  }

}