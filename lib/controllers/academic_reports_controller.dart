import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/academic_reports.dart';
import '../services/academic_service.dart';

enum ReportTab { offered, dropped, transcript }

class AcademicReportsController extends GetxController {
  final AcademicService _academicService = AcademicService();

  var selectedTab = ReportTab.offered.obs;
  var offeredCourses = <OfferedCourse>[].obs;
  var droppedCourses = <DroppedCourse>[].obs;
  var transcriptData = <String, List<TranscriptCourse>>{}.obs;

  var isLoading = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    ever(selectedTab, (_) => loadDataForActiveTab());
    loadDataForActiveTab();
  }

  Future<void> loadDataForActiveTab() async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('student_id');

    if (studentId == null) {
      errorMessage.value = "User not logged in";
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      switch (selectedTab.value) {
        case ReportTab.offered:
          if (offeredCourses.isEmpty) {
            final data = await _academicService.fetchOfferedCourses(studentId);
            offeredCourses.value = data;
          }
          break;
        case ReportTab.dropped:
          if (droppedCourses.isEmpty) {
            final data = await _academicService.fetchDroppedCourses(studentId);
            droppedCourses.value = data;
          }
          break;
        case ReportTab.transcript:
          if (transcriptData.isEmpty) {
            final data = await _academicService.fetchTranscript(studentId);
            Map<String, List<TranscriptCourse>> grouped = {};
            for (var course in data) {
              grouped.putIfAbsent(course.session, () => []).add(course);
            }
            transcriptData.value = grouped;
          }
          break;
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  String calculateGPA(List<TranscriptCourse> courses) {
    double totalPoints = 0;
    int totalCredits = 0;

    for (var course in courses) {
      double points = 0;
      switch (course.grade.toUpperCase()) {
        case "A": points = 4.0; break;
        case "A-": points = 3.67; break;
        case "B+": points = 3.33; break;
        case "B": points = 3.0; break;
        case "B-": points = 2.67; break;
        case "C+": points = 2.33; break;
        case "C": points = 2.0; break;
        case "C-": points = 1.67; break;
        case "D+": points = 1.33; break;
        case "D": points = 1.0; break;
        case "F": points = 0.0; break;
        default: continue;
      }
      totalPoints += points * course.creditHours;
      totalCredits += course.creditHours;
    }

    if (totalCredits == 0) return "0.00";
    return (totalPoints / totalCredits).toStringAsFixed(2);
  }
}
