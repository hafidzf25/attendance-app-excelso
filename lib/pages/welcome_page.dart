import 'package:absence_excelso/pages/attendance_page.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/index.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    // Request location saat app buka
    // _locationService.requestLocationPermissionAndGetLocation();
  }

  // Future<void> _requestCameraPermission() async {
  //   PermissionStatus status = await Permission.camera.request();
  //   if (status.isDenied) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Permission camera ditolak')),
  //     );
  //   } else if (status.isGranted) {
  //     // TODO: Buka camera atau lanjut ke halaman berikutnya
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Permission camera diizinkan')),
  //     );
  //   }
  // }

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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AttendancePage(),
                            ),
                          );
                        },
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 48),
                      const LocationInfo(),
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
