import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/teacher_controller.dart';
import '../../models/academic_reports.dart';
import '../components/constants.dart';

class TeacherDashboardv extends StatelessWidget {
  TeacherDashboardv({super.key});

  final TeacherController controller = Get.find<TeacherController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppGradients.primaryLight,
      appBar: AppBar(
        title: const Text('Weak Students'),
      ),
      body: Obx(() {
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

        if (controller.mystudents.isEmpty) {
          return const Center(child: Text("No weak students found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.mystudents.length,
          itemBuilder: (BuildContext context, int index) {
            return _buildStudentCard(controller.mystudents[index]);
          },
        );
      }),
    );
  }

  Widget _buildStudentCard(MyStudents student) {
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
                  "CGPA: ${student.cgpa} • ${student.sos}",
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