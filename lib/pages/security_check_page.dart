import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/security_service.dart';

class SecurityCheckPage extends StatefulWidget {
  const SecurityCheckPage({Key? key}) : super(key: key);

  @override
  State<SecurityCheckPage> createState() => _SecurityCheckPageState();
}

class _SecurityCheckPageState extends State<SecurityCheckPage> {
  final SecurityService _securityService = SecurityService();

  @override
  void initState() {
    super.initState();
    _checkSecurity();
  }

  Future<void> _checkSecurity() async {
    final status = await _securityService.checkDeviceSecurity();

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (status == SecurityStatus.safe) {
      // Device aman, lanjut ke aplikasi
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    } else {
      // Device tidak aman, tampilkan error dan block akses
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Security Check'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_securityService.isChecking)
                  _buildCheckingState()
                else if (_securityService.isSafe)
                  _buildSafeState()
                else
                  _buildBlockedState(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckingState() {
    return Column(
      children: [
        const SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 6,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Memeriksa Keamanan Perangkat...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tunggu sebentar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSafeState() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.1),
          ),
          child: const Icon(
            Icons.check_circle,
            size: 60,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Perangkat Aman',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Perangkat Anda telah lolos pemeriksaan keamanan.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBlockedState() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.1),
          ),
          child: const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Akses Ditolak',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _securityService.securityMessage ?? 'Perangkat ini tidak aman.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.red,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Alasan Penolakan:',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        _buildSecurityIssuesList(),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            // Coba check lagi
            setState(() {});
            _checkSecurity();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Coba Lagi'),
        ),
      ],
    );
  }

  Widget _buildSecurityIssuesList() {
    List<String> issues = [];

    if (_securityService.securityStatus == SecurityStatus.rooted) {
      issues.add('• Perangkat ter-root (sudah di-jailbreak)');
      issues.add('• Hapus akses root/jailbreak dari perangkat');
    } else if (_securityService.securityStatus ==
        SecurityStatus.developerMode) {
      issues.add('• Mode Pengembang aktif');
      issues.add('• Matikan Mode Pengembang di Pengaturan');
    } else if (_securityService.securityStatus ==
        SecurityStatus.mockLocation) {
      issues.add('• Deteksi penggunaan Mock Location');
      issues.add('• Gunakan lokasi GPS yang sebenarnya');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: issues
          .map((issue) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  issue,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ))
          .toList(),
    );
  }
}
