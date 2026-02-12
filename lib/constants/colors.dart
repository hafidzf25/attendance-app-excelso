import 'package:flutter/material.dart';

class AppColors {
  // Primary color
  static const Color primary = Color(0xff003267);
  
  // Status colors
  static const Color success = Color(0xff22c55e);
  static const Color danger = Color(0xffef4444);
  
  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xfff5f5f5),
      Color(0xffe8f4f8),
    ],
  );
  
  // Text colors
  static const Color textPrimary = Color(0xff003267);
  static const Color textSecondary = Color(0xff666666);
  
  // Others
  static const Color white = Colors.white;
}
