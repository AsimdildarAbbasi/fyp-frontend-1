import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/auth/login_view.dart';
import 'views/home/chat_sessions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if student is already logged in
  //final prefs = await SharedPreferences.getInstance();
 // final studentId = prefs.getString('student_id');
  
  runApp(FYPApp(isLoggedIn: false));
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
      home: isLoggedIn ? const ChatSessionsScreen() : LoginView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
