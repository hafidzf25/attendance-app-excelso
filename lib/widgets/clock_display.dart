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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 16,
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
              fontSize: 14,
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
