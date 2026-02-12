import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/welcome_page.dart';

void main() async {
  await initializeDateFormatting('id_ID', null);
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomePage(),
    );
  }
}
