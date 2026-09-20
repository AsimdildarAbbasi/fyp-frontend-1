import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session.dart';
import '../services/chat_service.dart';

class SideMenuController extends GetxController {
  final ChatService _chatService = ChatService();

  var chatSessions = <ChatSession>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('student_id');

    if (studentId == null) {
      errorMessage.value = "No Student ID found. Please log in again.";
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      chatSessions.value = await _chatService.fetchChatSessions(studentId);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  String formatFriendlyDate(String dateString) {
    try {
      final parsedDate = DateTime.parse(dateString);
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${months[parsedDate.month - 1]} ${parsedDate.day}";
    } catch (e) {
      return dateString.length > 10 ? dateString.substring(0, 10) : dateString;
    }
  }
}
