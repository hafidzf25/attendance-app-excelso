import 'package:absence_excelso/constants/colors.dart';
import 'package:absence_excelso/pages/camera_page.dart';
import 'package:absence_excelso/pages/success_enroll_page.dart';
import 'package:absence_excelso/services/index.dart';
import 'package:absence_excelso/widgets/index.dart';
import 'package:flutter/material.dart';

class EnrollPage extends StatefulWidget {
  const EnrollPage({super.key});

  @override
  State<EnrollPage> createState() => _EnrollPageState();
}

class _EnrollPageState extends State<EnrollPage> {
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final TextEditingController _nikController = TextEditingController();
  bool isLoading = false;

  void handleEnroll() async {
    setState(() {
      isLoading = true;
    });
    try {
      var data = await _attendanceRepository.getEnroll(
        employeeNumber: _nikController.text.trim(),
      );
      int enrollCount = data.faceEmbeddingCount ?? 0;
      if (data.maxFaceEmbeddings! > data.faceEmbeddingCount!) {
        do {
          String path = await _navigateToCameraPage();
          if (path.trim().isNotEmpty) {
            var dataPost = await _attendanceRepository.enrollFace(
              photoPath: path,
              employeeNumber: _nikController.text.trim(),
            );
            if (dataPost.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.success,
                  content: Text(
                      'Berhasil melakukan enroll! ${dataPost['faceEmbeddingCount']}/${dataPost['maxFaceEmbeddings']}'),
                ),
              );
              enrollCount++;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.danger,
                  content: Text('Gagal melakukan enroll!'),
                ),
              );
            }
          } else {
            enrollCount = data.maxFaceEmbeddings!;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppColors.danger,
                content: Text('Gagal melakukan enroll!'),
              ),
            );
          }
        } while (enrollCount < data.maxFaceEmbeddings!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Anda sudah terdaftar.'),
          ),
        );
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Error enroll: $e'),
        ),
      );
    }
    // int captureCounter = 0;
    // for (var i = 0; i < 4; i++) {
    //   String path = await _navigateToCameraPage();
    //   path.trim().isNotEmpty ? captureCounter++ : null;
    // }
    // if (captureCounter == 4) {
    //   Navigator.of(context).pushAndRemoveUntil(
    //     MaterialPageRoute(
    //       builder: (context) => const SuccessEnrollPage(),
    //     ),
    //     (route) => false,
    //   );
    // } else {
    //   Navigator.of(context).pop();
    // }
  }

  Future<String> _navigateToCameraPage() async {
    final photoPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraPage(
          typeRequest: "Enroll",
        ),
      ),
    );

    if (photoPath != null && mounted) {
      debugPrint("Photo path: $photoPath");
      return photoPath;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryHorizontal,
            // borderRadius: BorderRadius.only(
            //   bottomLeft: Radius.circular(32),
            //   bottomRight: Radius.circular(32),
            // ),
          ),
        ),
        title: Text(
          'Absensi Kehadiran',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontSize: isTablet ? 24 : 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 32 : 16,
            vertical: isTablet ? 52 : 50,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const WelcomeHeader(
                    title: 'Form Enroll',
                    subtitle: 'Isi NIK untuk mendaftarkan wajah',
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  _buildNikTextField(isTablet),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _nikController.text.trim().length != 8 || isLoading
                              ? null
                              : handleEnroll,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.app_registration_rounded,
                                  color: Colors.white,
                                ),
                                Text(
                                  "Enroll",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.5),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 18 : 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNikTextField(bool isTablet) {
    return FormTextField(
      label: '',
      hintText: 'Masukkan NIK',
      controller: _nikController,
      prefixIcon: Icons.badge,
      isTablet: isTablet,
      keyboardType: TextInputType.number,
      changeValue: (value) {
        setState(() {
          _nikController.text = value;
        });
      },
    );
  }
}
