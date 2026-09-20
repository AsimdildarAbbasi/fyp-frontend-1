import 'package:get/get.dart';
import '../services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();

  var email = ''.obs;
  var password = ''.obs;
  var selectedRole = 'Student'.obs;

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var navigateToHome = false.obs;

  Future<void> performLogin() async {
    if (email.value.isEmpty || password.value.isEmpty) {
      errorMessage.value = "Please enter both email and password.";
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await _authService.login(email.value, password.value);
      print("Successfully logged in as: ${response.name}");
      navigateToHome.value = true;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
