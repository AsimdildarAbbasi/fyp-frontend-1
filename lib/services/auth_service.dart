import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import '../network/network_manager.dart';

class AuthService {
  final NetworkManager _network = NetworkManager();

  Future<AuthResponse> login(String email, String password) async {
    final body = {
      "email": email,
      "password": password,
    };
    
    final data = await _network.request('/auth/login', 'POST', body: body);
    final authResponse = AuthResponse.fromJson(data);
    
    if (authResponse.studentId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('student_id', authResponse.studentId!);
    }
    
    return authResponse;
  }
}
