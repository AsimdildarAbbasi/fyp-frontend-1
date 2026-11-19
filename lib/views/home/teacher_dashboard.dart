import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/teacher_controller.dart';
import '../../models/teacher_model.dart';
import '../components/constants.dart'; // import your AppGradients
import 'bad_students.dart';

class TeacherDashboard extends StatelessWidget {
  TeacherDashboard({super.key});

  final TeacherController controller = Get.put(TeacherController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppGradients.primaryLight,
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    controller.loadweakstudents(); // Fetch weak students
                    Get.to(() => TeacherDashboardv());
                  },
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Weak Students'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (controller.sectionstudent.isEmpty) {
                return const Center(child: Text("No students found"));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.sectionstudent.length,
                itemBuilder: (context, index) {
                  return _buildStudentCard(controller.sectionstudent[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(ShowStudents student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.mainGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.sid,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "CGPA: ${student.cgpa} • ${student.name}",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        ],
      ),
    );
  }
}