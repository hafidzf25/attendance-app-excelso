import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';

class FormTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData prefixIcon;
  final bool isTablet;
  final int? maxLines;
  final int? minLines;
  final Function(String) changeValue;

  const FormTextField({
    Key? key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.prefixIcon,
    required this.isTablet,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines,
    required this.changeValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          onChanged: changeValue,
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: 8,
          minLines: minLines,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.textPrimary.withOpacity(0.5),
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}
