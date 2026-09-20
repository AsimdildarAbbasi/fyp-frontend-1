import 'package:flutter/material.dart';
import 'package:fyp_flutter/views/components/constants.dart';
import 'package:get/get.dart';
import '../../controllers/academic_reports_controller.dart';
import '../../models/academic_reports.dart';

class AcademicReportsView extends StatelessWidget {
  AcademicReportsView({super.key});

  final AcademicReportsController controller = Get.put(AcademicReportsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppGradients.primaryLight,
      appBar: AppBar(
        title: const Text('Academic Reports'),
        backgroundColor: AppGradients.primaryLight,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTabs(),
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

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (controller.selectedTab.value == ReportTab.offered)
                      ...controller.offeredCourses.map(_buildOfferedCourseCard),
                    if (controller.selectedTab.value == ReportTab.dropped)
                      ...controller.droppedCourses.map(_buildDroppedCourseCard),
                    if (controller.selectedTab.value == ReportTab.transcript)
                      ...(
                          controller.transcriptData.keys.toList()
                            ..sort((a, b) => b.compareTo(a))
                      ).map((session) => _buildTranscriptCard(
                        session,
                        controller.transcriptData[session]!,
                      )),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Obx(() => Row(
            children: ReportTab.values.map((tab) {
              final isSelected = controller.selectedTab.value == tab;
              String title = "";
              switch (tab) {
                case ReportTab.offered: title = "Offered Courses"; break;
                case ReportTab.dropped: title = "Dropped Courses"; break;
                case ReportTab.transcript: title = "Transcript"; break;
              }

              return GestureDetector(
                onTap: () => controller.selectedTab.value = tab,
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppGradients.mainGradient
                        : const LinearGradient(colors: [Colors.white12, Colors.white12]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          )),
    );
  }

  Widget _buildOfferedCourseCard(OfferedCourse course) {
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
                  course.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${course.courseId} • ${course.teacherName}",
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

  Widget _buildDroppedCourseCard(DroppedCourse course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppGradients.mainGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(width: 6, height: 80, color: Colors.orange),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.courseId,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.session,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildTranscriptCard(String session, List<TranscriptCourse> courses) {
  //   final gpa = controller.calculateGPA(courses);
  //   return Card(
  //
  //     color: const Color(0xFF1E293B),
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     margin: const EdgeInsets.only(bottom: 12),
  //     child: ExpansionTile(
  //       title: Text(
  //         session,
  //         style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
  //       ),
  //       subtitle: Text(
  //         "GPA: $gpa",
  //         style: const TextStyle(color: Colors.white70),
  //       ),
  //       iconColor: Colors.white,
  //       collapsedIconColor: Colors.white54,
  //       children: courses.map((course) {
  //         return Column(
  //           children: [
  //             const Divider(color: Colors.white12, height: 1),
  //             Padding(
  //               padding: const EdgeInsets.all(16),
  //               child: Row(
  //                 children: [
  //                   Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           course.courseId,
  //                           style: const TextStyle(
  //                             color: Colors.white54,
  //                             fontSize: 12,
  //                           ),
  //                         ),
  //                         const SizedBox(height: 4),
  //                         Text(
  //                           course.title,
  //                           style: const TextStyle(
  //                             fontWeight: FontWeight.w600,
  //                             color: Colors.white,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   Text(
  //                     course.grade,
  //                     style: const TextStyle(
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.white,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         );
  //       }).toList(),
  //     ),
  //   );
  //}
  Widget _buildTranscriptCard(String session, List<TranscriptCourse> courses) {
    final gpa = controller.calculateGPA(courses);

    return Card(
      color: Colors.transparent, // important
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppGradients.mainGradient, // your reusable gradient
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: EdgeInsets.zero,
          title: Text(
            session,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            "GPA: $gpa",
            style: const TextStyle(color: Colors.white70),
          ),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white54,
          children: courses.map((course) {
            return Column(
              children: [
                const Divider(color: Colors.white12, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.courseId,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              course.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        course.grade,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
