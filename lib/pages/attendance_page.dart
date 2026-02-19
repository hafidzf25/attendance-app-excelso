import 'package:absence_excelso/constants/colors.dart';
import 'package:absence_excelso/pages/camera_page.dart';
import 'package:absence_excelso/models/api_error.dart';
import 'package:absence_excelso/pages/result_page.dart';
import 'package:absence_excelso/services/attendance_repository.dart';
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
  bool _isSubmitting = false;

  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final LocationService _locationService = LocationService();

  String _selectedOutlet = 'Outlet 1';
  String? _selectedShift;
  // final TextEditingController _nikController = TextEditingController();

  List<String> _outlets = [
    'Outlet 1',
    'Outlet 2',
    'Outlet 3',
    'Outlet 4',
    'Outlet 5',
    'Outlet 6',
    'Outlet 7',
    'Outlet 8',
    'Outlet 9',
  ];

  final List<Map<String, String>> _shifts = [
    {'time': '06:00 - 14:00', 'name': 'Shift 1'},
    {'time': '14:00 - 22:00', 'name': 'Shift 2'},
    {'time': '22:00 - 06:00', 'name': 'Shift 3'},
    {'time': '06:00 - 14:00', 'name': 'Shift 4'},
    {'time': '14:00 - 22:00', 'name': 'Shift 5'},
    {'time': '22:00 - 06:00', 'name': 'Shift 6'},
    {'time': '06:00 - 14:00', 'name': 'Shift 7'},
    {'time': '14:00 - 22:00', 'name': 'Shift 8'},
    {'time': '22:00 - 06:00', 'name': 'Shift 9'},
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
      // Location failed, show error
      setState(() {
        _isPageInitialized = false;
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

  Future<void> _navigateToCameraPage(String actionType) async {
    final photoPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const CameraPage()),
    );

    if (photoPath != null && mounted) {
      await _submitAttendance(actionType, photoPath);
    }
  }

  // Ambil branch terdekat dari backend (dengan retry & cache)
  Future<void> _loadNearestBranches(bool isLocationOk) async {
    if (!isLocationOk) return;

    try {
      debugPrint("📍 Loading branches dengan lat: ${_locationService.currentPosition?.latitude}, "
          "long: ${_locationService.currentPosition?.longitude}");
      
      // getNearestBranches akan handle retry otomatis + caching
      final branches = await _attendanceRepository.getNearestBranches(
        latitude: _locationService.currentPosition!.latitude,
        longitude: _locationService.currentPosition!.longitude,
        radius: 0.075,
        useCache: true, // Gunakan cache jika tersedia
      );

      if (mounted) {
        setState(() {
          _outlets = branches.map((b) => b.name).toList();
          if (_outlets.isNotEmpty) {
            _selectedOutlet = _outlets[0];
            debugPrint("✅ Berhasil load ${_outlets.length} branch");
          } else {
            debugPrint("⚠️ Tidak ada branch di radius ini");
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading branches setelah retry: $e');
      // Jika semua retry gagal, tetap gunakan default outlets (fallback)
      if (mounted) {
        setState(() {
          _outlets = [
            'Outlet 1',
            'Outlet 2',
            'Outlet 3',
            'Outlet 4',
            'Outlet 5',
          ];
          _selectedOutlet = _outlets[0];
        });
      }
    }
  }

  Future<void> _submitAttendance(String actionType, String photoPath) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // final userId = _nikController.text.trim();
      var data = AttendanceRecord();
      if (actionType == 'Check In') {
        data = await _attendanceRepository.checkIn(
          photoPath: photoPath,
        );
      } else {
        // final today =
        //     await _attendanceRepository.getTodayAttendance(userId: userId);
        // if (today == null) {
        //   _showErrorSnackbar('Belum ada data check-in hari ini');
        //   return;
        // }
        // await _attendanceRepository.checkOut(attendanceId: today.id);
      }

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
    ).then((selectedShift) {
      if (selectedShift != null) {
        setState(() {
          _selectedShift = selectedShift;
        });
        // Navigate to camera page after shift is selected
        _navigateToCameraPage(actionType);
      }
    });
  }

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

  void _handleCheckIn() {
    // if (_nikController.text.trim().isEmpty) {
    //   _showErrorSnackbar('Silakan isi NIK terlebih dahulu');
    //   return;
    // }
    _showShiftModal('Check In');
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Absensi Kerja',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: !_isPageInitialized
          ? _buildLoadingState()
          : _buildFormContent(isTablet),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: const Center(
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
      ),
    );
  }

  Widget _buildFormContent(bool isTablet) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                kToolbarHeight -
                MediaQuery.of(context).padding.top,
          ),
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 16,
              vertical: isTablet ? 24 : 16,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WelcomeHeader(
                  title: 'Form Kehadiran',
                  subtitle: 'Silakan isi data untuk presensi',
                ),
                SizedBox(height: isTablet ? 32 : 24),
                const ClockDisplay(),
                SizedBox(height: isTablet ? 24 : 20),
                _buildOutletDropdown(isTablet),
                // SizedBox(height: isTablet ? 24 : 20),
                // _buildNikTextField(isTablet),
                SizedBox(height: isTablet ? 28 : 24),
                FormButtons(
                  onCheckIn: _handleCheckIn,
                  onCheckOut: _handleCheckOut,
                  isLoading: _isSubmitting,
                  isTablet: isTablet,
                  isBranchExists: _outlets.isNotEmpty,
                ),
                SizedBox(height: isTablet ? 28 : 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutletDropdown(bool isTablet) {
    return FormDropdown<String>(
      label: 'Pilih Outlet',
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
      prefixIcon: Icons.location_on,
      isTablet: isTablet,
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
