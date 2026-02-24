import 'dart:io';
import 'package:absence_excelso/constants/colors.dart';
import 'package:absence_excelso/pages/attendance_page.dart';
import 'package:absence_excelso/pages/success_enroll_page.dart';
import 'package:absence_excelso/services/index.dart';
import 'package:absence_excelso/widgets/index.dart';
import 'package:flutter/material.dart';

class PhotoReviewPage extends StatefulWidget {
  final String photoPath;
  final String? branchCode;
  final AttendanceIdentify? attendanceIdentify;
  final String? typeRequest;

  const PhotoReviewPage({
    super.key,
    required this.photoPath,
    this.branchCode,
    this.attendanceIdentify,
    this.typeRequest,
  });

  @override
  State<PhotoReviewPage> createState() => _PhotoReviewPageState();
}

class _PhotoReviewPageState extends State<PhotoReviewPage> {
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final LocationService _locationService = LocationService();
  bool isLoading = false;

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
    _loadLocation();
    if (widget.attendanceIdentify?.type == 'in') {
      _loadShift();
    }
  }

  void _loadLocation() async {
    debugPrint("1. Proses get lokasi");
    final locationOk = await _locationService.getCurrentLocation();
    if (!mounted) return;

    debugPrint("Lokasi saat ini: ${_locationService.currentPosition}");
    if (locationOk) {
      debugPrint("2. Lokasi udah oke");
      // Location OK, lanjut cek branch terdekat lalu inisiasi page nya
    } else {
      debugPrint("1.1 Nyampe ga");
      // Location failed, show error

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _locationService.errorMessage ??
                  'Gagal mengakses lokasi. Silakan coba lagi.',
            ),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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

    void _enrollFace() {
      setState(() {
        isLoading = true;
      });
      Navigator.pop(context, widget.photoPath);
    }

    void _showShiftModal(String actionType) async {
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
        (selectedShift) async {
          if (selectedShift != null) {
            setState(() {
              _selectedShift = selectedShift;
            });
            try {
              // Proses pengambilan shift
              final selectedShift = _shifts.cast<Shift?>().firstWhere(
                    (shift) =>
                        shift != null &&
                        '${shift.startTime} - ${shift.endTime}' ==
                            _selectedShift,
                    orElse: () => null,
                  );
              final shiftId = selectedShift?.id ?? 0;
              var data = await _attendanceRepository.confirmAttendance(
                branchCode: widget.branchCode!,
                latitude: double.parse(
                  _locationService.currentPosition!.latitude.toStringAsFixed(6),
                ),
                longitude: double.parse(
                  _locationService.currentPosition!.longitude
                      .toStringAsFixed(6),
                ),
                shiftId: shiftId,
                token: widget.attendanceIdentify?.token ?? '',
                type: 'in',
              );
              setState(() {
                isLoading = true;
              });
              if (data.isNotEmpty) {
                // Navigate to result page after shift is selected
                // Navigator.of(context).pushAndRemoveUntil(
                //     MaterialPageRoute(
                //       builder: (context) => const SuccessEnrollPage(),
                //     ),
                //     (route) => false);
                final result = await Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SuccessEnrollPage(),
                  ),
                  (route) => false,
                );
                if (result != null && mounted) {
                  Navigator.pop(context, result);
                }
              }
            } catch (e) {
              debugPrint('Error confirming attendance: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error confirming attendance: $e'),
                  ),
                );
              }
            }
          }
        },
      );
    }

    void checkOut() async {
      setState(() {
        isLoading = true;
      });
      try {
        var data = await _attendanceRepository.confirmAttendance(
          branchCode: widget.branchCode!,
          latitude: double.parse(
            _locationService.currentPosition!.latitude.toStringAsFixed(6),
          ),
          longitude: double.parse(
            _locationService.currentPosition!.longitude.toStringAsFixed(6),
          ),
          token: widget.attendanceIdentify?.token ?? '',
          type: 'out',
        );
        if (data.isNotEmpty) {
          final result = await Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const SuccessEnrollPage(),
            ),
            (route) => false,
          );
          if (result != null && mounted) {
            Navigator.pop(context, result);
          }
        }
      } catch (e) {
        debugPrint(e.toString());
        if (mounted) {
          String pesan;
          if (e.toString().contains('No open attendance found to Check Out')) {
            pesan = 'Anda sudah melakukan absensi hari ini.';
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const AttendancePage(),
              ),
              (route) => false,
            );
          } else {
            pesan = 'Error confirming attendance: $e';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(pesan),
            ),
          );
          if (pesan != 'Anda sudah melakukan absensi hari ini.') {
            setState(() {
              isLoading = false;
            });
          }
        }
      }
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : SafeArea(
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
                            widget.typeRequest == 'Enroll'
                                ? 'Pastikan Gambar sudah sesuai'
                                : 'Pastikan Data sudah sesuai',
                            style: TextStyle(
                              fontSize: isTablet ? 32 : 20,
                              fontWeight: FontWeight.w700,
                              foreground: Paint()
                                ..shader =
                                    AppColors.primaryHorizontal.createShader(
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
                    widget.typeRequest == 'Enroll'
                        ? const SizedBox.shrink()
                        : Container(
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
                              onPressed: () => widget.typeRequest == 'Enroll'
                                  ? _enrollFace()
                                  : widget.attendanceIdentify?.type == 'in'
                                      ? _showShiftModal('')
                                      : checkOut(),
                              icon: widget.typeRequest == 'Enroll'
                                  ? const Icon(Icons.app_registration)
                                  : widget.attendanceIdentify?.type == 'in'
                                      ? const Icon(Icons.input)
                                      : const Icon(Icons.output),
                              label: Text(
                                widget.typeRequest == 'Enroll'
                                    ? 'Enroll'
                                    : widget.attendanceIdentify?.type == 'in'
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
