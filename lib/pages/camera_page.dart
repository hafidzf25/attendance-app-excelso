import 'package:absence_excelso/constants/colors.dart';
import 'package:absence_excelso/pages/photo_review_page.dart';
import 'package:absence_excelso/services/camera_service.dart';
import 'package:absence_excelso/services/face_detection_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final CameraService _cameraService = CameraService();
  final FaceDetectionService _faceDetectionService = FaceDetectionService();

  bool _isLoading = true;
  bool _isProcessing = false;
  int _frameCounter = 0;

  // Face detection state
  bool _faceDetected = false;
  int _faceQualityScore = 0;
  String _faceStatus = 'Mendeteksi wajah...';
  int _faceCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _faceDetectionService.initialize();

    final success = await _cameraService.initializeCamera();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (success) {
        _setupCropPreview();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  _cameraService.errorMessage ?? 'Error initializing camera'),
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
      // Process setiap 5 frame (~6x per detik pada 30fps camera)
      if (_frameCounter % 5 == 0 && !_isProcessing) {
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
      final faces = await _faceDetectionService.detectFaces(image);
      final hasValidFace = _faceDetectionService.hasValidFace(faces);
      final faceCount = faces.length;

      if (mounted) {
        int qualityScore = 0;
        String statusText = 'Wajah tidak terdeteksi';
        bool canCapture = false;

        if (faceCount > 1) {
          statusText = 'Terdeteksi $faceCount wajah. Hanya 1 orang!';
          canCapture = false;
        } else if (faceCount == 1 && hasValidFace) {
          final bestFace = _faceDetectionService.getBestFace(faces);
          if (bestFace != null) {
            qualityScore = bestFace.getQualityScore(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            );

            if (qualityScore >= 80) {
              statusText = 'Sempurna!';
            } else if (qualityScore >= 60) {
              statusText = 'Bagus, posisikan lebih baik';
            } else {
              statusText = 'Posisikan wajah di center';
            }
            canCapture = true;
          }
        }

        setState(() {
          _faceDetected = canCapture;
          _faceQualityScore = qualityScore;
          _faceStatus = statusText;
          _faceCount = faceCount;
        });
      }
    } catch (e) {
      debugPrint('Preview error: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_faceCount > 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Terdeteksi $_faceCount wajah. Pastikan hanya 1 orang di frame!'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    if (!_faceDetected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Posisikan wajah Anda untuk mengambil foto'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    if (_faceQualityScore < 30) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kualitas wajah kurang baik. Posisikan lebih baik.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    try {
      final controller = _cameraService.cameraController;
      if (controller != null && controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }

      final photoPath = await _cameraService.capturePhoto();
      if (photoPath != null && mounted) {
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoReviewPage(photoPath: photoPath),
          ),
        );

        if (result != null && mounted) {
          Navigator.pop(context, result);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(_cameraService.errorMessage ?? 'Error capturing photo'),
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
    } finally {
      final controller = _cameraService.cameraController;
      if (mounted &&
          controller != null &&
          !controller.value.isStreamingImages) {
        _setupCropPreview();
      }
    }
  }

  @override
  void dispose() {
    final controller = _cameraService.cameraController;
    if (controller != null && controller.value.isStreamingImages) {
      controller.stopImageStream();
    }
    _cameraService.dispose();
    _faceDetectionService.dispose();
    super.dispose();
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
      body: _isLoading ? _buildLoadingState() : _buildCameraPreview(isTablet),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
            SizedBox(height: 24),
            Text(
              'Menginisialisasi kamera dan face detection...',
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final circleSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth * 0.85
            : constraints.maxHeight * 0.75;

        return Stack(
          children: [
            // Full camera preview with proper aspect ratio
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraService
                          .cameraController!.value.previewSize?.height ??
                      1,
                  height: _cameraService
                          .cameraController!.value.previewSize?.width ??
                      1,
                  child: CameraPreview(_cameraService.cameraController!),
                ),
              ),
            ),
            // Blur effect outside circle
            Positioned.fill(
              child: ClipPath(
                clipper: _InvertedCircleClipper(circleSize: circleSize),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _faceCount > 1
                            ? Colors.red.withOpacity(0.8)
                            : _faceDetected
                                ? Colors.green.withOpacity(0.7)
                                : Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _faceStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: const Alignment(0, 0),
                      child: SizedBox(
                        width: circleSize,
                        height: circleSize,
                        child: CustomPaint(
                          painter: _CircleFrameDarkenPainter(
                            frameColor: _faceCount > 1
                                ? Colors.red
                                : _faceDetected
                                    ? Colors.green
                                    : AppColors.primary,
                          ),
                          size: Size(circleSize, circleSize),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Column(
                      children: [
                        // ClipRRect(
                        //   borderRadius: BorderRadius.circular(8),
                        //   child: LinearProgressIndicator(
                        //     value: _faceQualityScore / 100,
                        //     minHeight: 8,
                        //     backgroundColor: Colors.grey.withOpacity(0.3),
                        //     valueColor: AlwaysStoppedAnimation(
                        //       _faceDetected && _faceQualityScore >= 80
                        //           ? Colors.green
                        //           : _faceDetected && _faceQualityScore >= 60
                        //               ? Colors.orange
                        //               : Colors.red,
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 8),
                        // Text(
                        //   'Kualitas Wajah: $_faceQualityScore/100',
                        //   style: const TextStyle(
                        //     color: Colors.white,
                        //     fontSize: 12,
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                        FloatingActionButton.extended(
                          onPressed: _capturePhoto,
                          backgroundColor:
                              _faceDetected && _faceQualityScore >= 50
                                  ? AppColors.success
                                  : Colors.grey,
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
      },
    );
  }
}

class _CircleFrameDarkenPainter extends CustomPainter {
  final Color frameColor;

  _CircleFrameDarkenPainter({required this.frameColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // final radius = size.width / 2;

    // Draw circle border
    // final borderPaint = Paint()
    //   ..color = frameColor
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 4;
    // canvas.drawCircle(center, radius, borderPaint);

    // Draw guide lines (cross hair)
    final guidePaint = Paint()
      ..color = frameColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - 20, center.dy),
      Offset(center.dx + 20, center.dy),
      guidePaint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - 20),
      Offset(center.dx, center.dy + 20),
      guidePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InvertedCircleClipper extends CustomClipper<Path> {
  final double circleSize;

  _InvertedCircleClipper({required this.circleSize});

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = circleSize / 2;

    // Add outer rectangle
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Subtract circle (inverted clip)
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    path.fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
