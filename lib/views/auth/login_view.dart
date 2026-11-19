import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/login_controller.dart';
import '../../network/network_manager.dart';
import '../components/constants.dart';
import '../home/chat_sessions_screen.dart';
import '../home/teacher_dashboard.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController controller = Get.put(LoginController());
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    controller.resetState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopSection(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildFormCard(context),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFD3E3F0),
            Color(0xFFE4EEF6),
            Color(0xFFF3F7FA),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 〰️ Subtle EEG Waveform in background
          Positioned.fill(
            child: CustomPaint(
              painter: EegWavePainter(),
            ),
          ),

          // ⚙️ Top-Right Settings Gear Icon
          Positioned(
            top: topPadding > 0 ? topPadding + 10 : 20,
            right: 18,
            child: GestureDetector(
              onTap: () => _showServerSettingsDialog(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B9FB3),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          // 📖 Center Branding: Open Book Icon in Squircle + Title
          Center(
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding > 0 ? topPadding + 28 : 42,
                bottom: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3A64),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F3A64).withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "University AI Advisor",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0F6),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Welcome Back"
          const Text(
            "Welcome Back",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),

          // "Sign in with your BIIT account"
          const Text(
            "Sign in with your BIIT account",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),

          // Email Address Label
          const Text(
            "Email Address",
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),

          // Email Input Box
          TextField(
            onChanged: (val) => controller.email.value = val,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: "email@BIIT.EDU",
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(
                Icons.mail_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0F3A64), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Password Label
          const Text(
            "Password",
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),

          // Password Input Box
          TextField(
            onChanged: (val) => controller.password.value = val,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.performLogin(),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: "Password",
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(
                Icons.lock_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0F3A64), width: 1.5),
              ),
            ),
          ),

          // Error Message Display
          Obx(() {
            if (controller.errorMessage.value.isNotEmpty) {
              final err = controller.errorMessage.value;
              final isConnError = err.contains("SocketException") ||
                  err.contains("Connection refused") ||
                  err.contains("Failed host lookup") ||
                  err.contains("timed out") ||
                  err.contains("ClientException");

              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      err,
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12.5),
                    ),
                    if (isConnError) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _showServerSettingsDialog(context),
                        child: const Text(
                          "Wrong IP? Tap here or settings gear above to configure IP.",
                          style: TextStyle(
                            color: Color(0xFF0F3A64),
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

          const SizedBox(height: 28),

          // 🚀 Sign In Button
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F3A64)),
                  ),
                ),
              );
            }

            return SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0A3A6B),
                      Color(0xFF052342),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF052342).withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => controller.performLogin(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
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
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
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
                      color: const Color(0xFF0F3A64).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.dns_rounded,
                        color: Color(0xFF0F3A64), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Backend Server IP",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Enter your PC/server IP and port to connect Flutter to the FastAPI backend:",
                      style: TextStyle(fontSize: 12.5, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        labelText: "Host / IP : Port",
                        hintText: "192.168.1.27:8000",
                        prefixIcon: const Icon(Icons.lan_rounded, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
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
                    const SizedBox(height: 8),
                    Text(
                      "Base URL: $previewUrl",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontFamily: 'monospace',
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
                                  final res = await NetworkManager.testConnection(
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
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.network_check_rounded,
                                  size: 18),
                          label: Text(isTesting ? "Testing..." : "Test Connection"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F3A64),
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
                        backgroundColor: const Color(0xFF0F3A64),
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                        margin: const EdgeInsets.all(16),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3A64),
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

/// Subtle EEG waveform painter in the top header
class EegWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB0CDE5).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final h = size.height * 0.48;

    // Left waveform
    path.moveTo(0, h);
    path.lineTo(size.width * 0.08, h);
    path.lineTo(size.width * 0.12, h - 8);
    path.lineTo(size.width * 0.16, h + 12);
    path.lineTo(size.width * 0.20, h - 35);
    path.lineTo(size.width * 0.23, h + 22);
    path.lineTo(size.width * 0.26, h);
    path.lineTo(size.width * 0.33, h);

    // Right waveform
    path.moveTo(size.width * 0.67, h);
    path.lineTo(size.width * 0.73, h);
    path.lineTo(size.width * 0.77, h - 10);
    path.lineTo(size.width * 0.80, h + 20);
    path.lineTo(size.width * 0.83, h - 38);
    path.lineTo(size.width * 0.86, h + 18);
    path.lineTo(size.width * 0.90, h - 5);
    path.lineTo(size.width * 0.93, h);
    path.lineTo(size.width, h);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
