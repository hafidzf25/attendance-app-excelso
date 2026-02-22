import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../constants/colors.dart';

class ClockDisplay extends StatefulWidget {
  const ClockDisplay({super.key});

  @override
  State<ClockDisplay> createState() => _ClockDisplayState();
}

class _ClockDisplayState extends State<ClockDisplay> {
  late DateTime _currentDateTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _currentDateTime = DateTime.now();

    // Update time every 1 second only for clock, not entire page
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentDateTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.symmetric(horizontal: 16, vertical: isTablet ? 32 : 24),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/bunga.png'),
          alignment: Alignment.centerLeft,
          fit: BoxFit.contain,
        ),
        borderRadius: BorderRadius.circular(18),
        gradient: AppColors.primaryHorizontal,
        boxShadow: [
          BoxShadow(
            color: const Color(0xff000000).withOpacity(0.1),
            offset: const Offset(0, 10),
            blurRadius: 15,
            spreadRadius: -3,
          ),
          BoxShadow(
            color: const Color(0xff000000).withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 6,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            DateFormat('HH:mm:ss').format(_currentDateTime),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            // DateFormat('EEEE, d MMMM yyyy', 'id_ID')
            DateFormat('d MMMM yyyy', 'id_ID').format(_currentDateTime),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
