import 'package:flutter/material.dart';
import 'package:fyp_flutter/views/components/constants.dart';
import 'package:get/get.dart';
import '../../controllers/side_menu_controller.dart';

class SideMenu extends StatelessWidget {
  final Function(int?) onSessionSelected;

  SideMenu({super.key, required this.onSessionSelected});

  final SideMenuController controller = Get.put(SideMenuController());

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppGradients.primaryLight,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: const Text(
                "Chat History",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              children: [
                Expanded( // 1. Expands to take all available space in the Row/Column
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 45, // Set a fixed height for the button
                      decoration: BoxDecoration(
                        gradient: AppGradients.mainGradient,
                        borderRadius: BorderRadius.circular(8), // Make sure this matches the button's shape
                      ),
                      child: ElevatedButton(
                        onPressed: () => onSessionSelected(null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, // 2. Let the gradient show through
                          shadowColor: Colors.transparent,     // 3. Remove default button shadow
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "New Chat",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.chatSessions.isEmpty) {
                  return const Center(
                    child: Text(
                      "No chat history yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: controller.chatSessions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final session = controller.chatSessions[index];
                    return ListTile(
                      title: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        controller.formatFriendlyDate(session.startTime),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      onTap: () => onSessionSelected(session.id),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
