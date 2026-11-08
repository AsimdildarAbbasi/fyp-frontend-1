import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'network/network_manager.dart';
import 'views/auth/login_view.dart';
import 'views/home/chat_sessions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NetworkManager.init();
  
  final prefs = await SharedPreferences.getInstance();
  final studentId = prefs.getString('student_id');
  
  runApp(FYPApp(isLoggedIn: studentId != null && studentId.isNotEmpty));
}

class FYPApp extends StatelessWidget {
  final bool isLoggedIn;
  
  const FYPApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'FYP Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFE6ECF2),
      ),
      home:LoginView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
