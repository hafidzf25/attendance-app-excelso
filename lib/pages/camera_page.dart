import 'package:absence_excelso/constants/colors.dart';
import 'package:absence_excelso/services/camera_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final CameraService _cameraService = CameraService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final success = await _cameraService.initializeCamera();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_cameraService.errorMessage ?? 'Error initializing camera'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final photoPath = await _cameraService.capturePhoto();
      if (photoPath != null && mounted) {
        // Bisa return photo path ke halaman sebelumnya
        Navigator.pop(context, photoPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
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
          'Ambil Foto',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _buildCameraPreview(isTablet),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Menginisialisasi kamera...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(bool isTablet) {
    if (_cameraService.cameraController == null ||
        !_cameraService.isInitialized) {
      return Center(
        child: Text(
          _cameraService.errorMessage ?? 'Camera not available',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      );
    }

    return Stack(
      children: [
        // Camera Preview
        CameraPreview(_cameraService.cameraController!),

        // Overlay with frame guide
        SafeArea(
          child: Stack(
            children: [
              // Frame guide untuk face detection area
              Align(
                alignment: const Alignment(0, -0.3),
                child: Container(
                  width: isTablet ? 400 : 300,
                  height: isTablet ? 400 : 300,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              // Top label
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Posisikan wajah di dalam frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom buttons
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cancel button
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Batal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
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
                      const SizedBox(width: 16),
                      // Capture button
                      FloatingActionButton.extended(
                        onPressed: _capturePhoto,
                        backgroundColor: AppColors.success,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Ambil Foto'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
