import 'package:absence_excelso/pages/attendance_page.dart';
import 'package:absence_excelso/services/location_service.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/index.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final LocationService _locationService = LocationService();
  bool _isCheckingLocation = false;

  Future<void> _handleAbsenPress() async {
    if (_isCheckingLocation) return;

    setState(() {
      _isCheckingLocation = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mengecek lokasi...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Check location
    final locationOk = await _locationService.getCurrentLocation();

    if (!mounted) return;

    // Close loading dialog
    Navigator.pop(context);

    if (locationOk) {
      // Location OK, navigate to attendance page
      setState(() {
        _isCheckingLocation = false;
      });
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AttendancePage(),
          ),
        );
      }
    } else {
      // Location failed, show error
      setState(() {
        _isCheckingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _locationService.errorMessage ??
                  'Gagal mengakses lokasi. Silakan coba lagi.',
            ),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(
            "Excelso Attendance",
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 16,
                  vertical: 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const WelcomeHeader(),
                      const SizedBox(height: 48),
                      CircularActionButton(
                        onPressed: _isCheckingLocation ? null : () => _handleAbsenPress(),
                        isTablet: isTablet,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
