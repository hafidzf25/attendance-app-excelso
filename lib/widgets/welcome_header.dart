import 'package:flutter/material.dart';
import '../constants/colors.dart';

class WelcomeHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const WelcomeHeader({
    Key? key,
    this.title = 'Excelso Attendance',
    this.subtitle = 'Silakan lakukan absensi sesuai jadwal kerja Anda',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .center,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
