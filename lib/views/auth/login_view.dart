import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/login_controller.dart';
import '../../network/network_manager.dart';
import '../components/constants.dart';
import '../home/chat_sessions_screen.dart';

class LoginView extends StatelessWidget {
  LoginView({super.key});

  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    ever(controller.navigateToHome, (bool navigate) {
      if (navigate) {
        Get.offAll(() => ChatSessionsScreen());
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopCard(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildFormCard(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCard(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFE6ECF2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE6ECF2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppGradients.mainGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(2, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.book,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "University AI Advisor",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                ValueListenableBuilder<String>(
                  valueListenable: NetworkManager.baseURLNotifier,
                  builder: (context, _, __) {
                    return GestureDetector(
                      onTap: () => _showServerSettingsDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black.withOpacity(0.06)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi, size: 12, color: Color(0xFF245C94)),
                            const SizedBox(width: 5),
                            Text(
                              NetworkManager.displayHost,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF245C94),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top > 0
                ? MediaQuery.of(context).padding.top + 6
                : 14,
            right: 14,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _showServerSettingsDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Color(0xFF0B1C2D),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFFE6ECF2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(2, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => Row(
                  children: [
                    Expanded(
                      child: _buildRoleButton(
                        "Student",
                        controller.selectedRole.value == "Student",
                        () => controller.selectedRole.value = "Student",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildRoleButton(
                        "Teacher",
                        controller.selectedRole.value == "Teacher",
                        () => controller.selectedRole.value = "Teacher",
                      ),
                    ),
                  ],
                )),
            const SizedBox(height: 30),
            const Text("Email Address", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildTextField(
              hint: "abc@gmail.com",
              icon: Icons.email,
              onChanged: (val) => controller.email.value = val,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            const Text("Password", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildTextField(
              hint: "Password",
              icon: Icons.lock,
              isPassword: true,
              onChanged: (val) => controller.password.value = val,
            ),
            Obx(() {
              if (controller.errorMessage.value.isNotEmpty) {
                final err = controller.errorMessage.value;
                final isConnError = err.contains("SocketException") ||
                    err.contains("Connection refused") ||
                    err.contains("Failed host lookup") ||
                    err.contains("timed out") ||
                    err.contains("ClientException");
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        err,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                      if (isConnError) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _showServerSettingsDialog(context),
                          child: const Text(
                            "Wrong IP? Tap here or settings icon above to change IP.",
                            style: TextStyle(
                              color: Color(0xFF245C94),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 40),
            Obx(() => controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child:Container(
                      decoration: BoxDecoration(
                        gradient: AppGradients.mainGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () => controller.performLogin(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      onChanged: onChanged,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  void _showServerSettingsDialog(BuildContext context) {
    final currentUrl = NetworkManager.baseURL;
    final uri = Uri.tryParse(currentUrl);
    final initialHost = uri != null
        ? (uri.hasPort ? '${uri.host}:${uri.port}' : uri.host)
        : currentUrl;

    final textController = TextEditingController(text: initialHost);
    String previewUrl = NetworkManager.formatBaseUrl(initialHost);
    bool isTesting = false;
    String? testResult;
    bool testSuccess = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppGradients.mainGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.settings_ethernet_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Server IP Settings",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Enter your computer's Wi-Fi IP address or host:",
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: textController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: "Server IP / Host",
                        hintText: "e.g. 192.168.1.27 or 192.168.1.27:8000",
                        prefixIcon:
                            const Icon(Icons.wifi, color: Color(0xFF245C94)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            textController.clear();
                            setDialogState(() {
                              previewUrl = NetworkManager.formatBaseUrl("");
                              testResult = null;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          previewUrl = NetworkManager.formatBaseUrl(val);
                          testResult = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Resolved Target Base URL:",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          SelectableText(
                            previewUrl,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: isTesting
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isTesting = true;
                                    testResult = null;
                                  });
                                  final res =
                                      await NetworkManager.testConnection(
                                          textController.text);
                                  setDialogState(() {
                                    isTesting = false;
                                    testSuccess = res['success'] == true;
                                    testResult = res['message']?.toString();
                                  });
                                },
                          icon: isTesting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.network_check_rounded, size: 18),
                          label: Text(
                              isTesting ? "Testing..." : "Test Connection"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF245C94),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              textController.text =
                                  NetworkManager.defaultBaseURL;
                              previewUrl = NetworkManager.defaultBaseURL;
                              testResult = null;
                            });
                          },
                          child: const Text(
                            "Reset",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    if (testResult != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: testSuccess
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: testSuccess
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFCA5A5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                testSuccess
                                    ? Icons.check_circle_rounded
                                    : Icons.error_outline_rounded,
                                size: 16,
                                color: testSuccess
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                testResult!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: testSuccess
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await NetworkManager.setBaseURL(textController.text);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      Get.snackbar(
                        "Server IP Updated",
                        "Now pointing to: ${NetworkManager.baseURL}",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFF0B1C2D),
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                        margin: const EdgeInsets.all(16),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF245C94),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
