import 'package:absence_excelso/constants/colors.dart';
import 'package:absence_excelso/services/index.dart';
import 'package:absence_excelso/widgets/index.dart';
import 'package:absence_excelso/widgets/clock_display.dart';
import 'package:flutter/material.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final LocationService _locationService = LocationService();
  bool _isPageInitialized = false;
  
  String _selectedOutlet = 'Outlet 1';
  final TextEditingController _nikController = TextEditingController();
  
  final List<String> _outlets = ['Outlet 1', 'Outlet 2', 'Outlet 3'];

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _locationService.getCurrentLocation();
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

  void _handleCheckIn() {
    if (_nikController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan isi NIK'), backgroundColor: Colors.red),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Check In: ${_nikController.text} - $_selectedOutlet')),
    );
  }

  void _handleCheckOut() {
    if (_nikController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan isi NIK'), backgroundColor: Colors.red),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Check Out: ${_nikController.text} - $_selectedOutlet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Absensi Kerja',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: !_isPageInitialized
          ? Center(
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
            )
          : SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 16,
              vertical: isTablet ? 24 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                WelcomeHeader(
                  title: 'Form Kehadiran',
                  subtitle: 'Silakan isi data untuk presensi',
                ),
                SizedBox(height: isTablet ? 32 : 24),

                // Date & Time Card
                const ClockDisplay(),
                SizedBox(height: isTablet ? 24 : 20),

                // Outlet Selection
                Text(
                  'Pilih Outlet',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedOutlet,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _outlets.map((String outlet) {
                      return DropdownMenuItem<String>(
                        value: outlet,
                        child: Text(outlet),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedOutlet = newValue ?? _selectedOutlet;
                      });
                    },
                  ),
                ),
                SizedBox(height: isTablet ? 24 : 20),

                // NIK Input
                Text(
                  'Nomor Induk Karyawan (NIK)',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nikController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Masukkan NIK',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.badge, color: AppColors.primary),
                  ),
                ),
                SizedBox(height: isTablet ? 28 : 24),

                // Check In & Check Out Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleCheckIn,
                        icon: const Icon(Icons.login),
                        label: const Text('Check In'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 16 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleCheckOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Check Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 16 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 28 : 24),

                // Debug Location Info
                ListenableBuilder(
                  listenable: _locationService,
                  builder: (context, _) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📍 DEBUG: Lokasi',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_locationService.isLoading)
                            const SizedBox(
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (_locationService.errorMessage != null)
                            Text(
                              _locationService.errorMessage!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                              ),
                            )
                          else if (_locationService.currentPosition != null)
                            Text(
                              'Lat: ${_locationService.currentPosition!.latitude.toStringAsFixed(6)}, '
                              'Lon: ${_locationService.currentPosition!.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 11),
                            )
                          else
                            const Text(
                              'Lokasi belum tersedia',
                              style: TextStyle(fontSize: 11),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

