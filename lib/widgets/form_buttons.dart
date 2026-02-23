import 'package:flutter/material.dart';
import '../constants/colors.dart';

class FormButtons extends StatelessWidget {
  final VoidCallback onEnroll;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;
  final bool isLoading;
  final bool isTablet;
  final bool isBranchExists;

  const FormButtons({
    Key? key,
    required this.onEnroll,
    required this.onCheckIn,
    required this.onCheckOut,
    this.isLoading = false,
    required this.isTablet,
    this.isBranchExists = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading || !isBranchExists ? null : onEnroll,
            style: ElevatedButton.styleFrom(
              side: BorderSide(
                color: isLoading || !isBranchExists
                    ? Colors.white
                    : const Color(0xff0C8FB0),
                width: 2,
              ),
              backgroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
              padding: EdgeInsets.symmetric(
                vertical: isTablet ? 18 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.app_registration_rounded,
                  color: isLoading || !isBranchExists
                      ? Colors.white
                      : const Color(0xff0C8FB0),
                ),
                const SizedBox(width: 8),
                Text(
                  'Enroll',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: isLoading || !isBranchExists
                        ? Colors.white
                        : const Color(0xff0C8FB0),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading || !isBranchExists ? null : onCheckIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
              padding: EdgeInsets.symmetric(
                vertical: isTablet ? 18 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Absen',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
