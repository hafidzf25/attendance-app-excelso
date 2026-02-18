import 'package:absence_excelso/constants/colors.dart';
import 'package:absence_excelso/pages/photo_review_page.dart';
import 'package:absence_excelso/services/camera_service.dart';
import 'package:absence_excelso/utils/image_utils.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final CameraService _cameraService = CameraService();
  bool _isLoading = true;
  Uint8List? _cropPreview;
  bool _isProcessing = false;
  int _frameCounter = 0; // Frame counter untuk skip frames

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
      if (success) {
        // Setup image stream for crop preview
        _setupCropPreview();
      } else {
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

  void _setupCropPreview() {
    _cameraService.cameraController?.startImageStream((image) {
      _frameCounter++;
      // Process only every 3rd frame untuk reduce CPU/memory usage
      if (_frameCounter % 3 == 0 && !_isProcessing) {
        _isProcessing = true;
        _processCropPreview(image).then((_) {
          _isProcessing = false;
        }).catchError((e) {
          debugPrint('Error processing crop preview: $e');
          _isProcessing = false;
        });
      }
    }).catchError((e) {
      debugPrint('Error in image stream: $e');
    });
  }

  Future<void> _processCropPreview(CameraImage image) async {
    try {
      // Convert camera image to img.Image
      final bytes = _concatenatePlanes(image);
      if (bytes.isEmpty) return;
      
      final decoded = img.decodeImage(bytes);
      
      if (decoded != null && mounted) {
        // Apply fitAndCrop to get preview
        final cropped = ImageUtils.fitAndCrop(decoded, 480, 512);
        if (cropped != null) {
          // Resize untuk preview (480x512 → 240x256) untuk hemat memory
          // Use ImageUtils.resize untuk consistency
          final previewResized = ImageUtils.resize(cropped, 240, 256);
          
          if (previewResized != null) {
            // Encode ke JPG dengan quality rendah (50 untuk hemat memory)
            final preview = ImageUtils.encodeToJpg(previewResized, 50);
            if (mounted) {
              setState(() {
                _cropPreview = Uint8List.fromList(preview);
              });
            }
          }
        }
      }
      
      // Clear bytes to prevent memory leak
      bytes.clear();
    } catch (e) {
      debugPrint('Preview error: $e');
    }
  }

  Uint8List _concatenatePlanes(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  Future<void> _capturePhoto() async {
    try {
      // CRITICAL: Stop image stream BEFORE taking picture to prevent race condition
      // This prevents crash di Android camera framework
      await _cameraService.cameraController?.stopImageStream();
      
      final photoPath = await _cameraService.capturePhoto();
      if (photoPath != null && mounted) {
        // Navigate to photo review page
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoReviewPage(photoPath: photoPath),
          ),
        );
        
        // Return result to previous page (AttendancePage)
        if (result != null && mounted) {
          Navigator.pop(context, result);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_cameraService.errorMessage ?? 'Error capturing photo'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
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
    _cameraService.cameraController?.stopImageStream();
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
        // Camera Preview (fill screen)
        CameraPreview(_cameraService.cameraController!),

        // Overlay with instruction, frame guide, and buttons
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top instruction
              Padding(
                padding: const EdgeInsets.all(16),
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
              
              // Center frame guide - using AspectRatio for exact 480:512 match
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AspectRatio(
                      aspectRatio: 480 / 512,
                      child: Stack(
                        children: [
                          // Show crop preview if available (BRIGHT inside frame)
                          if (_cropPreview != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                _cropPreview!,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          // Dark overlay OUTSIDE frame area
                          CustomPaint(
                            painter: _OutsideFrameDarkenPainter(
                              frameColor: AppColors.primary,
                            ),
                            size: Size.infinite,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Bottom buttons
              Padding(
                padding: const EdgeInsets.all(16),
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
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter untuk draw dark overlay OUTSIDE frame area only
class _OutsideFrameDarkenPainter extends CustomPainter {
  final Color frameColor;

  _OutsideFrameDarkenPainter({required this.frameColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Full rect dan frame rect
    final frameRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final frameRRect = RRect.fromRectAndRadius(frameRect, const Radius.circular(16));

    // Create path untuk full rect
    final fullPath = Path()..addRect(frameRect);
    
    // Create path untuk frame (inside area)
    final framePath = Path()..addRRect(frameRRect);

    // Get outside area only (full - frame)
    final outsidePath = Path.combine(PathOperation.difference, fullPath, framePath);

    // Paint dark overlay ONLY on outside area
    final darkPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(outsidePath, darkPaint);

    // Draw frame border
    final borderPaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(frameRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
