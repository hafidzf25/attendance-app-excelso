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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                .format(_currentDateTime),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('HH:mm:ss').format(_currentDateTime),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
