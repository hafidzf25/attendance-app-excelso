import 'package:absence_excelso/constants/colors.dart';
import 'package:absence_excelso/pages/welcome_page.dart';
import 'package:absence_excelso/services/attendance_repository.dart';
import 'package:flutter/material.dart';

class ResultPage extends StatefulWidget {
  final AttendanceRecord? attendanceRecord;
  const ResultPage({this.attendanceRecord, super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Hasil Absensi",
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
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
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.primary,
                        size: 100,
                      ),
                      const SizedBox(height: 48),
                      const Text(
                        "Absensi Berhasil",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  offset: const Offset(1, 1))
                            ]),
                        child: Column(children: [
                          Row(
                            children: [
                              const Expanded(
                                flex: 3,
                                child: Text(
                                  "Nama",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Expanded(
                                flex: 1,
                                child: Text(
                                  ":",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: Text(
                                    widget.attendanceRecord?.name ?? 'N/A'),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Expanded(
                                flex: 3,
                                child: Text(
                                  "NIK",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Expanded(
                                flex: 1,
                                child: Text(
                                  ":",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child:
                                    Text(widget.attendanceRecord?.nik ?? 'N/A'),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Expanded(
                                flex: 3,
                                child: Text(
                                  "Similarity",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Expanded(
                                flex: 1,
                                child: Text(
                                  ":",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: Text(
                                  "${((widget.attendanceRecord?.similarity ?? 0.0) * 100).round()} %"
                                ),
                              ),
                            ],
                          ),
                        ]),
                      ),
                      const SizedBox(height: 48),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const WelcomePage()),
                            (route) => false,
                          );
                        },
                        child: const Text("Kembali ke Desktop"),
                      )
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
