import 'package:absence_excelso/constants/colors.dart';
import 'package:absence_excelso/pages/camera_page.dart';
import 'package:absence_excelso/models/api_error.dart';
import 'package:absence_excelso/pages/enroll_page.dart';
import 'package:absence_excelso/pages/result_page.dart';
import 'package:absence_excelso/services/index.dart';
import 'package:absence_excelso/widgets/index.dart';
import 'package:flutter/material.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with WidgetsBindingObserver {
  bool _isPageInitialized = false;
  bool _isRefreshBranch = false;
  bool _isSubmitting = false;

  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final LocationService _locationService = LocationService();

  // String _selectedOutlet = 'Outlet 1';
  String _selectedOutlet = '';
  String? _selectedShift;
  List<Branch> _branches = [];
  // final TextEditingController _nikController = TextEditingController();

  List<String> _outlets = [
    // 'Outlet 1',
    // 'Outlet 2',
    // 'Outlet 3',
    // 'Outlet 4',
    // 'Outlet 5',
    // 'Outlet 6',
    // 'Outlet 7',
    // 'Outlet 8',
    // 'Outlet 9',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePage();
  }

  @override
  void dispose() {
    // _nikController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      // App kembali ke foreground
      debugPrint("App dibuka lagi");
      _initializePage();
    }
    if (state == AppLifecycleState.paused) {
      debugPrint("App masuk background");
    }
  }

  Future<void> _initializePage() async {
    // Location sudah diambil dari welcome page (LocationService singleton)
    // Jadi disini hanya perlu set initialized flag
    // Bisa add minimal delay untuk UX yang lebih smooth
    await Future.delayed(const Duration(milliseconds: 300));

    _isPageInitialized = false;
    setState(() {});

    debugPrint("1. Proses get lokasi");
    final locationOk = await _locationService.getCurrentLocation();
    if (!mounted) return;

    if (locationOk) {
      debugPrint("2. Lokasi udah oke");
      // Location OK, lanjut cek branch terdekat lalu inisiasi page nya

      // Pengambilan branch terdekat dari backend
      debugPrint("3. Proses get branch");
      await _loadNearestBranches(locationOk);

      debugPrint("4. Branch udah oke");
      if (mounted) {
        setState(() {
          _isPageInitialized = true;
        });
      }
    } else {
      debugPrint("1.1 Nyampe ga");
      // Location failed, show error
      setState(() {
        _isPageInitialized = true;
      });

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

  Future<void> _navigateToCameraPage(String actionType) async {
    setState(() {
      _isRefreshBranch = true;
    });

    final photoPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraPage(
          typeRequest: "Attendance",
        ),
      ),
    );

    if (photoPath != null && mounted) {
      await _submitAttendance(actionType, photoPath);
    }

    setState(() {
      _isRefreshBranch = false;
    });
  }

  Future<void> refreshBranches() async {
    if (_isRefreshBranch) return;

    setState(() {
      _outlets = [];
      _isRefreshBranch = true;
    });

    try {
      final locationOk = await _locationService.getCurrentLocation();
      if (locationOk) {
        await _loadNearestBranches(locationOk);
      } else {
        debugPrint("Gagal refresh branch: ${_locationService.errorMessage}");
      }
    } catch (e) {
      debugPrint("Error refresh branch: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshBranch = false;
        });
      }
    }
  }

  // Ambil branch terdekat dari backend
  Future<void> _loadNearestBranches(bool isLocationOk) async {
    try {
      if (isLocationOk) {
        final branches = await _attendanceRepository.getNearestBranches(
          latitude: double.parse(
            _locationService.currentPosition!.latitude.toStringAsFixed(6),
          ),
          longitude: double.parse(
            _locationService.currentPosition!.longitude.toStringAsFixed(6),
          ),
          radius: 0.075, // radius dalam km
        );

        if (mounted) {
          setState(() {
            _branches = branches;
            _outlets = branches.map((b) {
              final satuanMeter = b.distanceKm! * 100;
              return "${b.name} (${satuanMeter.toStringAsFixed(2)} m)";
            }).toList();
            _selectedOutlet = _outlets.isNotEmpty ? _outlets[0] : 'Outlet 1';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading branches: $e');
      // Jika error, gunakan default outlets
    }
  }

  Future<void> _submitAttendance(String actionType, String photoPath) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // final currentPosition = _locationService.currentPosition;
      // final latitude = currentPosition?.latitude ?? 0;
      // final longitude = currentPosition?.longitude ?? 0;
      // final type = actionType == 'Check In' ? 'in' : 'out';
      // final selectedShift = _shifts.cast<Shift?>().firstWhere(
      //       (shift) =>
      //           shift != null &&
      //           '${shift.startTime} - ${shift.endTime}' == _selectedShift,
      //       orElse: () => null,
      //     );
      // final shiftId = selectedShift?.id ?? 0;
      // final selectedOutletIndex = _outlets.indexOf(_selectedOutlet);
      // final branchCode =
      //     (selectedOutletIndex >= 0 && selectedOutletIndex < _branches.length)
      //         ? _branches[selectedOutletIndex].code
      //         : '';

      // final userId = _nikController.text.trim();
      var data = AttendanceIdentify();
      data = await _attendanceRepository.identify(photoPath: photoPath);
      // if (actionType == 'Check In') {
      //   data = await _attendanceRepository.checkIn(
      //     photoPath: photoPath,
      //     latitude: latitude,
      //     longitude: longitude,
      //     type: type,
      //     shiftId: shiftId,
      //     branchCode: branchCode,
      //   );
      // } else {
      //   data = await _attendanceRepository.checkOut(
      //     photoPath: photoPath,
      //     latitude: latitude,
      //     longitude: longitude,
      //     type: type,
      //     branchCode: branchCode,
      //   );
      // }

      _showSuccessSnackbar(actionType, photoPath);
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
        builder: (context) {
          return ResultPage(
            attendanceRecord: data,
          );
        },
      ), (route) => false);
    } on ApiError catch (e) {
      _showErrorSnackbar(e.message);
    } catch (e) {
      _showErrorSnackbar('Gagal $actionType: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // void _showShiftModal(String actionType) {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //     ),
  //     builder: (context) => ShiftSelectionModal(
  //       shifts: _shifts,
  //       initialShift: _selectedShift,
  //       actionType: actionType,
  //     ),
  //   ).then((selectedShift) {
  //     if (selectedShift != null) {
  //       setState(() {
  //         _selectedShift = selectedShift;
  //       });
  //       // Navigate to camera page after shift is selected
  //       _navigateToCameraPage(actionType);
  //     }
  //   });
  // }

  void _showSuccessSnackbar(String actionType, [String? photoPath]) {
    final photoInfo = photoPath != null ? ' ✓' : '';
    final message = actionType == 'Check Out'
        // ? '$actionType: ${_nikController.text} - $_selectedOutlet$photoInfo'
        // : '$actionType: ${_nikController.text} - $_selectedOutlet - $_selectedShift$photoInfo';
        ? '$actionType - $_selectedOutlet$photoInfo'
        : '$actionType - $_selectedOutlet - $_selectedShift$photoInfo';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );

    final raw = {
      'action': actionType,
      // 'nik': _nikController.text,
      'outlet': _selectedOutlet,
      'shift': _selectedShift,
      'photoPath': photoPath,
    };
    print("Attendance data: $raw");
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  void _handleEnroll() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return const EnrollPage();
      },
    ));
  }

  void _handleCheckIn() {
    // if (_nikController.text.trim().isEmpty) {
    //   _showErrorSnackbar('Silakan isi NIK terlebih dahulu');
    //   return;
    // }
    _navigateToCameraPage('Check In');
  }

  void _handleCheckOut() {
    // if (_nikController.text.trim().isEmpty) {
    //   _showErrorSnackbar('Silakan isi NIK terlebih dahulu');
    //   return;
    // }
    // For check out, navigate directly to camera (no shift modal)
    _navigateToCameraPage('Check Out');
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
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              )),
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
        centerTitle: true,
      ),
      body: !_isPageInitialized
          ? _buildLoadingState()
          : !_locationService.isMockLocation
              ? _buildFormContent(isTablet)
              : _buildErrorState(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
          SizedBox(height: 24),
          Text(
            'Mempersiapkan halaman presensi...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 24),
            Text(
              'Kamu terciduk',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent(bool isTablet) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                kToolbarHeight -
                MediaQuery.of(context).padding.top,
          ),
          decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/bunga-2.png'),
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight),
          ),
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 16,
              vertical: isTablet ? 52 : 50,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WelcomeHeader(
                      title: 'Form Kehadiran',
                      subtitle: 'Silakan isi data untuk presensi hari ini',
                    ),
                    SizedBox(height: isTablet ? 50 : 46),
                    const ClockDisplay(),
                    SizedBox(height: isTablet ? 64 : 60),
                    !_isRefreshBranch
                        ? _buildOutletDropdown(isTablet)
                        : const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary),
                            ),
                          ),
                    // SizedBox(height: isTablet ? 24 : 20),
                    // _buildNikTextField(isTablet),
                  ],
                ),
                Column(
                  children: [
                    FormButtons(
                      onEnroll: _handleEnroll,
                      onCheckIn: _handleCheckIn,
                      onCheckOut: _handleCheckOut,
                      isLoading: _isSubmitting,
                      isTablet: isTablet,
                      isBranchExists: _outlets.isNotEmpty,
                    ),
                    // SizedBox(height: isTablet ? 28 : 24),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutletDropdown(bool isTablet) {
    return FormDropdown<String>(
      label: 'Pilih Lokasi yang Sesuai',
      value: _selectedOutlet,
      items: _outlets,
      itemLabel: (outlet) => outlet,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedOutlet = value;
          });
        }
      },
      prefixIcon: Icons.location_on_outlined,
      isTablet: isTablet,
      refreshBranch: refreshBranches,
    );
  }

  // Widget _buildNikTextField(bool isTablet) {
  //   return FormTextField(
  //     label: 'Nomor Induk Karyawan (NIK)',
  //     hintText: 'Masukkan NIK',
  //     controller: _nikController,
  //     prefixIcon: Icons.badge,
  //     isTablet: isTablet,
  //     keyboardType: TextInputType.number,
  //   );
  // }
}
