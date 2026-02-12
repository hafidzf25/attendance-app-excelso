import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CircularActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isTablet;

  const CircularActionButton({
    Key? key,
    required this.onPressed,
    required this.isTablet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonSize = isTablet ? 120.0 : 80.0;

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.document_scanner,
                size: isTablet ? 28 : 20,
              ),
              SizedBox(height: isTablet ? 8 : 4),
              Text(
                'Absen',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
