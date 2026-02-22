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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  foreground: Paint()
                    ..shader = AppColors.primaryHorizontal.createShader(
                      const Rect.fromLTWH(0, 0, 200, 70),
                    ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              foreground: Paint()
                ..shader = AppColors.primaryHorizontal.createShader(
                  const Rect.fromLTWH(0, 0, 200, 70),
                ),
            ),
          ),
        ),
      ],
    );
  }
}
