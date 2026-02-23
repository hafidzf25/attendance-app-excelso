import 'dart:io';
import 'package:absence_excelso/constants/colors.dart';
import 'package:absence_excelso/pages/success_enroll_page.dart';
import 'package:absence_excelso/services/attendance_repository.dart';
import 'package:absence_excelso/widgets/index.dart';
import 'package:flutter/material.dart';

class PhotoReviewPage extends StatefulWidget {
  final String photoPath;
  final AttendanceIdentify? attendanceIdentify;

  const PhotoReviewPage({
    super.key,
    required this.photoPath,
    this.attendanceIdentify,
  });

  @override
  State<PhotoReviewPage> createState() => _PhotoReviewPageState();
}

class _PhotoReviewPageState extends State<PhotoReviewPage> {
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  List<Shift> _shifts = [
    Shift(
      id: 1,
      ordering: 1,
      startTime: DateTime(2026, 2, 20, 15, 30),
      endTime: DateTime(2026, 2, 20, 18, 30),
    ),
    Shift(
      id: 2,
      ordering: 2,
      startTime: DateTime(2026, 2, 21, 15, 30),
      endTime: DateTime(2026, 2, 21, 18, 30),
    ),
  ];
  String? _selectedShift;

  @override
  void initState() {
    super.initState();
    _loadShift();
  }

  // Ambil shift dari backend
  Future<void> _loadShift() async {
    try {
      final shift = await _attendanceRepository.getShift();

      if (mounted) {
        setState(() {
          _shifts = shift;
        });
      }
    } catch (e) {
      debugPrint('Error loading shift: $e');
      // Jika error, gunakan default outlets
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;

    void _showShiftModal(String actionType) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => ShiftSelectionModal(
          shifts: _shifts,
          initialShift: _selectedShift,
          actionType: actionType,
        ),
      ).then(
        (selectedShift) {
          if (selectedShift != null) {
            setState(() {
              _selectedShift = selectedShift;
            });
            // Navigate to result page after shift is selected
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const SuccessEnrollPage(),
                ),
                (route) => false);
          }
        },
      );
    }

    void checkOut() {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const SuccessEnrollPage(),
          ),
          (route) => false);
    }

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryHorizontal,
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Photo display container
              Container(
                padding: const EdgeInsets.all(16),
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 400 : 300,
                  maxHeight: isTablet ? 462 : 360,
                ),
                child: Column(
                  children: [
                    // Title
                    Text(
                      'Pastikan Data sudah sesuai',
                      style: TextStyle(
                        fontSize: isTablet ? 32 : 20,
                        fontWeight: FontWeight.w700,
                        foreground: Paint()
                          ..shader = AppColors.primaryHorizontal.createShader(
                            const Rect.fromLTWH(0, 0, 200, 70),
                          ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Photo with border
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(widget.photoPath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Office Excelso Jatibaru',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Nama',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 7,
                          child: Text(
                            " ${widget.attendanceIdentify?.employeeName}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'NIK',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 7,
                          child: Text(
                            " ${widget.attendanceIdentify?.employeeNumber}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Absen',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 7,
                          child: Text(
                            " ${widget.attendanceIdentify?.type?.toUpperCase()}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Retake button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                          'Ulangi',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.danger,
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 32 : 24,
                            vertical: isTablet ? 16 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                              width: 2,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Submit button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => widget.attendanceIdentify?.type == 'in'
                            ? _showShiftModal('')
                            : checkOut(),
                        icon: widget.attendanceIdentify?.type == 'in'
                            ? const Icon(Icons.input)
                            : const Icon(Icons.output),
                        label: Text(
                          widget.attendanceIdentify?.type == 'in'
                              ? 'Absen In'
                              : 'Absen Out',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 32 : 24,
                            vertical: isTablet ? 16 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    // FloatingActionButton.extended(
                    //   onPressed: () => Navigator.pop(context, photoPath),
                    //   backgroundColor: AppColors.success,
                    //   icon: const Icon(Icons.check_circle),
                    //   label: const Text('Kirim'),
                    // ),
                  ],
                ),
              ),
              // Action buttons
            ],
          ),
        ),
      ),
    );
  }
}
