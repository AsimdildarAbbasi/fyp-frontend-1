import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../views/home/chat_sessions_screen.dart';
import '../views/home/teacher_dashboard.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();

  var email = ''.obs;
  var password = ''.obs;
  var selectedRole = 'Student'.obs;
  var role = '';

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var navigateToHome = false.obs;

  @override
  void onInit() {
    super.onInit();
    resetState();
  }

  void resetState() {
    isLoading.value = false;
    errorMessage.value = '';
    navigateToHome.value = false;
  }

  Future<void> performLogin() async {
    if (email.value.isEmpty || password.value.isEmpty) {
      errorMessage.value = "Please enter both email and password.";
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    navigateToHome.value = false;

    try {
      final response = await _authService.login(email.value, password.value);
      print("Successfully logged in as: ${response.name}");
      role = response.role;
      navigateToHome.value = true;

      // Direct, reliable navigation on successful authentication
      if (role == "Student") {
        Get.offAll(() => ChatSessionsScreen());
      } else if (role == "Teacher") {
        Get.offAll(() => TeacherDashboard());
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
