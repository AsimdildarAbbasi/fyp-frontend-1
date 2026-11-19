import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/academic_reports.dart';
import '../services/academic_service.dart';
import '../models/teacher_model.dart';
import '../services/teacher_service.dart';


class TeacherController extends GetxController {
  final AcademicService _academicService = AcademicService();
  final Teacher_Service _teacher_service = Teacher_Service();


  var mystudents = <MyStudents>[].obs;
  var sectionstudent = <ShowStudents>[].obs;



  var isLoading = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadDataForActiveTab();
  }

  Future<void> loadDataForActiveTab() async {

    isLoading.value = true;
    errorMessage.value = '';

    try {
          if (sectionstudent.isEmpty) {
            final data = await _teacher_service.fetchmystudents(167);
            sectionstudent.value = data;
          }
        
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

    Future<void> loadweakstudents() async {

    isLoading.value = true;
    errorMessage.value = '';

    try {
          if (mystudents.isEmpty) {
            final data = await _academicService.fetchmystudents(2);
            mystudents.value = data;
          }
        
      }
     catch (e) {
      errorMessage.value = e.toString();
    }
    finally {
      isLoading.value = false;
    }
    }
}
