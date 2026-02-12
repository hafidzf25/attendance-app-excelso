import 'package:absence_excelso/constants/colors.dart';
import 'package:absence_excelso/pages/camera_page.dart';
import 'package:absence_excelso/widgets/index.dart';
import 'package:flutter/material.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool _isPageInitialized = false;

  String _selectedOutlet = 'Outlet 1';
  String? _selectedShift;
  final TextEditingController _nikController = TextEditingController();

  final List<String> _outlets = ['Outlet 1', 'Outlet 2', 'Outlet 3'];
  final List<Map<String, String>> _shifts = [
    {'time': '06:00 - 14:00', 'name': 'Shift Pagi'},
    {'time': '14:00 - 22:00', 'name': 'Shift Sore'},
    {'time': '22:00 - 06:00', 'name': 'Shift Malam'},
  ];

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    // Location sudah diambil dari welcome page (LocationService singleton)
    // Jadi disini hanya perlu set initialized flag
    // Bisa add minimal delay untuk UX yang lebih smooth
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted) {
      setState(() {
        _isPageInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _nikController.dispose();
    super.dispose();
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

  Future<void> _navigateToCameraPage(String actionType) async {
    final photoPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const CameraPage()),
    );

    if (photoPath != null && mounted) {
      _showSuccessSnackbar(actionType, photoPath);
    }
  }

  void _showSuccessSnackbar(String actionType, [String? photoPath]) {
    final photoInfo = photoPath != null ? ' ✓' : '';
    final message = actionType == 'Check Out'
        ? '$actionType: ${_nikController.text} - $_selectedOutlet$photoInfo'
        : '$actionType: ${_nikController.text} - $_selectedOutlet - $_selectedShift$photoInfo';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
    
    final raw = {
      'action': actionType,
      'nik': _nikController.text,
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
    if (_nikController.text.trim().isEmpty) {
      _showErrorSnackbar('Silakan isi NIK terlebih dahulu');
      return;
    }
    _showShiftModal('Check In');
  }

  void _handleCheckOut() {
    if (_nikController.text.trim().isEmpty) {
      _showErrorSnackbar('Silakan isi NIK terlebih dahulu');
      return;
    }
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
      decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
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
                WelcomeHeader(
                  title: 'Form Kehadiran',
                  subtitle: 'Silakan isi data untuk presensi',
                ),
                SizedBox(height: isTablet ? 32 : 24),
                const ClockDisplay(),
                SizedBox(height: isTablet ? 24 : 20),
                _buildOutletDropdown(isTablet),
                SizedBox(height: isTablet ? 24 : 20),
                _buildNikTextField(isTablet),
                SizedBox(height: isTablet ? 28 : 24),
                FormButtons(
                  onCheckIn: _handleCheckIn,
                  onCheckOut: _handleCheckOut,
                  isTablet: isTablet,
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

  Widget _buildNikTextField(bool isTablet) {
    return FormTextField(
      label: 'Nomor Induk Karyawan (NIK)',
      hintText: 'Masukkan NIK',
      controller: _nikController,
      prefixIcon: Icons.badge,
      isTablet: isTablet,
      keyboardType: TextInputType.number,
    );
  }
}
