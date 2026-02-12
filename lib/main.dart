import 'package:flutter/material.dart';
import 'pages/welcome_page.dart';
import 'pages/security_check_page.dart';

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SecurityCheckPage(),
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/security': (context) => const SecurityCheckPage(),
      },
    );
  }
}
