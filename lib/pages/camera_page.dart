import 'package:absence_excelso/constants/colors.dart';
import 'package:absence_excelso/pages/photo_review_page.dart';
import 'package:absence_excelso/services/attendance_repository.dart';
import 'package:absence_excelso/services/camera_service.dart';
import 'package:absence_excelso/services/face_detection_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math' as math;
import 'dart:ui';

class CameraPage extends StatefulWidget {
  final String? typeRequest;
  final String? branchCode;
  const CameraPage({
    super.key,
    required this.typeRequest,
    this.branchCode,
  });

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  static const int _requiredStableFrames = 5;
  static const int _detectionFrameInterval = 5;
  static const int _autoCaptureMinScore = 80;
  static const Duration _autoCaptureCooldown = Duration(seconds: 2);

  final CameraService _cameraService = CameraService();
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  bool _isLoading = true;
  bool _isLoadingPost = true;
  bool _isProcessing = false;
  bool _isCapturingPhoto = false;
  int _frameCounter = 0;

  // Face detection state
  bool _faceDetected = false;
  int _faceQualityScore = 0;
  String _faceStatus = 'Mendeteksi wajah...';
  int _faceCount = 0;
  int _stableGoodFrameCount = 0;
  bool _isAutoCaptureInProgress = false;
  DateTime? _lastAutoCaptureTime;
  Size? _previewLayoutSize;
  Size? _frameOvalSize;

  double get _autoCaptureProgress =>
      (_stableGoodFrameCount / _requiredStableFrames).clamp(0.0, 1.0);

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
        _isLoadingPost = false;
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
    final controller = _cameraService.cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }

    controller.startImageStream((image) {
      _frameCounter++;
      // Process setiap beberapa frame untuk kurangi delay trigger auto-capture
      if (_frameCounter % _detectionFrameInterval == 0 && !_isProcessing) {
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
      final detectedFaces = await _faceDetectionService.detectFaces(image);
      final faces = _filterFacesInsideFrame(detectedFaces, image);
      final hasValidFace = _faceDetectionService.hasValidFace(faces);
      final faceCount = faces.length;
      final hasFaceOutsideFrame = detectedFaces.isNotEmpty && faceCount == 0;

      if (mounted) {
        int qualityScore = 0;
        String statusText = 'Wajah tidak terdeteksi';
        bool canCapture = false;
        int nextStableCount = 0;

        if (hasFaceOutsideFrame) {
          statusText = 'Posisikan wajah di dalam frame';
        }

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

        final bestFace = _faceDetectionService.getBestFace(faces);

        final isStableGoodFace = canCapture &&
            qualityScore >= _autoCaptureMinScore &&
            bestFace != null &&
            _faceDetectionService.isFaceStable(bestFace);

        if (isStableGoodFace) {
          nextStableCount =
              math.min(_stableGoodFrameCount + 1, _requiredStableFrames);
          if (!_isAutoCaptureInProgress &&
              nextStableCount < _requiredStableFrames) {
            statusText =
                'Tahan posisi... ${nextStableCount}/$_requiredStableFrames';
          }
        }

        final shouldAutoCapture = isStableGoodFace &&
            nextStableCount >= _requiredStableFrames &&
            !_isAutoCaptureInProgress;

        if (!isStableGoodFace) {
          nextStableCount = 0;
        }

        if (shouldAutoCapture) {
          statusText = 'Mengambil foto otomatis...';
        }

        setState(() {
          _faceDetected = canCapture;
          _faceQualityScore = qualityScore;
          _faceStatus = statusText;
          _faceCount = faceCount;
          _stableGoodFrameCount = nextStableCount;
        });

        if (shouldAutoCapture) {
          await _triggerAutoCapture();
        }
      }
    } catch (e) {
      debugPrint('Preview error: $e');
    }
  }

  Future<void> _triggerAutoCapture() async {
    if (_isAutoCaptureInProgress) return;

    final now = DateTime.now();
    final lastCaptureTime = _lastAutoCaptureTime;
    if (lastCaptureTime != null &&
        now.difference(lastCaptureTime) < _autoCaptureCooldown) {
      return;
    }

    _isAutoCaptureInProgress = true;
    _lastAutoCaptureTime = now;

    try {
      await _capturePhoto(isAutoCapture: true);
    } finally {
      _isAutoCaptureInProgress = false;
      if (mounted) {
        setState(() {
          _stableGoodFrameCount = 0;
        });
      }
    }
  }

  List<Face> _filterFacesInsideFrame(List<Face> faces, CameraImage image) {
    if (faces.isEmpty) return faces;

    final layoutSize = _previewLayoutSize;
    final frameOvalSize = _frameOvalSize;
    if (layoutSize == null || frameOvalSize == null) {
      return faces;
    }

    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    // 1. Cek apakah sensor kamera landscape tapi layar portrait (umumnya rotasi 90/270 derajat)
    final isRotated =
        imageWidth > imageHeight && layoutSize.height > layoutSize.width;

    // 2. Swap dimensi image untuk kalkulasi scale yang akurat
    final logicalImageWidth = isRotated ? imageHeight : imageWidth;
    final logicalImageHeight = isRotated ? imageWidth : imageHeight;

    final previewScale = math.max(
      layoutSize.width / logicalImageWidth,
      layoutSize.height / logicalImageHeight,
    );

    if (previewScale <= 0) {
      return faces;
    }

    // 3. VITAL: Swap dimensi oval UI saat di-mapping ke raw image kamera yang "tidur"
    final mappedOvalWidth =
        isRotated ? frameOvalSize.height : frameOvalSize.width;
    final mappedOvalHeight =
        isRotated ? frameOvalSize.width : frameOvalSize.height;

    final frameRadiusXInImage = (mappedOvalWidth / 2) / previewScale;
    final frameRadiusYInImage = (mappedOvalHeight / 2) / previewScale;

    // Titik tengah gambar selalu sama terlepas dari rotasi
    final frameCenterInImage = Offset(imageWidth / 2, imageHeight / 2);

    if (frameRadiusXInImage <= 0 || frameRadiusYInImage <= 0) {
      return faces;
    }

    return faces.where((face) {
      final center = face.getFaceCenter();
      final dx = center.dx - frameCenterInImage.dx;
      final dy = center.dy - frameCenterInImage.dy;

      final ellipseDistance =
          (dx * dx) / (frameRadiusXInImage * frameRadiusXInImage) +
              (dy * dy) / (frameRadiusYInImage * frameRadiusYInImage);

      // Menggunakan angka 1.15 sebagai toleransi (buffer) anti-tremor
      // agar tidak hilang-timbul saat di perbatasan garis
      return ellipseDistance <= 1.15;
    }).toList();
  }

  Future<void> _capturePhoto({bool isAutoCapture = false}) async {
    if (_isAutoCaptureInProgress && !isAutoCapture) {
      return;
    }

    if (_isCapturingPhoto || !mounted) {
      return;
    }

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
      _isCapturingPhoto = true;

      if (mounted) {
        setState(() {
          _stableGoodFrameCount = 0;
        });
      }

      final controller = _cameraService.cameraController;
      if (controller == null || !controller.value.isInitialized) {
        throw Exception('Camera belum siap untuk capture');
      }

      if (controller.value.isTakingPicture) {
        return;
      }

      if (controller.value.isStreamingImages) {
        try {
          await controller.stopImageStream();
        } catch (e) {
          debugPrint('Error stopping image stream before capture: $e');
        }
      }

      await Future.delayed(const Duration(milliseconds: 80));

      final photoPath = await _cameraService.capturePhoto();
      if (photoPath != null && mounted) {
        if (widget.typeRequest == 'Attendance') {
          setState(() {
            _isLoadingPost = true;
          });
          var data = AttendanceIdentify();
          data = await _attendanceRepository.identify(photoPath: photoPath);
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) => PhotoReviewPage(
                photoPath: photoPath,
                attendanceIdentify: data,
                branchCode: widget.branchCode,
                typeRequest: widget.typeRequest,
              ),
            ),
          );
          setState(() {
            _isLoadingPost = false;
          });
          if (result != null && mounted) {
            Navigator.pop(context, result);
          }
        } else {
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) => PhotoReviewPage(
                photoPath: photoPath,
                typeRequest: widget.typeRequest,
              ),
            ),
          );
          if (result != null && mounted) {
            Navigator.pop(context, result);
          }
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
        setState(() {
          _isLoadingPost = false;
        });
      }
    } finally {
      _isCapturingPhoto = false;
      final controller = _cameraService.cameraController;
      if (mounted &&
          controller != null &&
          controller.value.isInitialized &&
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
    // JANGAN dispose FaceDetectionService - singleton harus tetap active
    // untuk enrollment loop atau penggunaan camera page berkali-kali
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
      body: _isLoading
          ? _buildLoadingState()
          : _isLoadingPost
              ? _buildLoadingPost()
              : _buildCameraPreview(isTablet),
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

  Widget _buildLoadingPost() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
            SizedBox(height: 24),
            Text(
              'Mencocokkan wajah ...',
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
        double frameWidth = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth * 0.72
            : constraints.maxHeight * 0.52;
        double frameHeight = frameWidth * 1.28;

        final maxFrameHeight = constraints.maxHeight * 0.72;
        if (frameHeight > maxFrameHeight) {
          final scale = maxFrameHeight / frameHeight;
          frameHeight = maxFrameHeight;
          frameWidth *= scale;
        }

        _previewLayoutSize = Size(constraints.maxWidth, constraints.maxHeight);
        _frameOvalSize = Size(frameWidth, frameHeight);

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
            // Blur effect outside oval frame
            Positioned.fill(
              child: ClipPath(
                clipper: _InvertedOvalClipper(
                  frameWidth: frameWidth,
                  frameHeight: frameHeight,
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.white.withOpacity(0.8),
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
                        width: frameWidth,
                        height: frameHeight,
                        child: Stack(
                          children: [
                            // Positioned.fill(
                            //   child: CustomPaint(
                            //     painter: _OvalFrameDarkenPainter(
                            //       frameColor: _faceCount > 1
                            //           ? Colors.red
                            //           : _faceDetected
                            //               ? Colors.green
                            //               : AppColors.primary,
                            //       progress: _autoCaptureProgress,
                            //     ),
                            //     size: Size(frameWidth, frameHeight),
                            //   ),
                            // ),
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 18,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: _autoCaptureProgress,
                                  minHeight: 7,
                                  backgroundColor: Colors.white24,
                                  valueColor: AlwaysStoppedAnimation(
                                    _autoCaptureProgress >= 1
                                        ? AppColors.success
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  // Padding(
                  //   padding: const EdgeInsets.all(16),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     children: [
                  //       ElevatedButton.icon(
                  //         onPressed: () => Navigator.pop(context),
                  //         icon: const Icon(Icons.close),
                  //         label: const Text('Batal'),
                  //         style: ElevatedButton.styleFrom(
                  //           backgroundColor: AppColors.danger,
                  //           foregroundColor: Colors.white,
                  //           padding: EdgeInsets.symmetric(
                  //             horizontal: isTablet ? 32 : 24,
                  //             vertical: isTablet ? 16 : 12,
                  //           ),
                  //           shape: RoundedRectangleBorder(
                  //             borderRadius: BorderRadius.circular(8),
                  //           ),
                  //         ),
                  //       ),
                  //       const SizedBox(width: 16),
                  //       FloatingActionButton.extended(
                  //         onPressed: _capturePhoto,
                  //         backgroundColor:
                  //             _faceDetected && _faceQualityScore >= 50
                  //                 ? AppColors.success
                  //                 : Colors.grey,
                  //         icon: const Icon(Icons.camera_alt),
                  //         label: const Text('Ambil Foto'),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// class _OvalFrameDarkenPainter extends CustomPainter {
//   final Color frameColor;
//   final double progress;

//   _OvalFrameDarkenPainter({
//     required this.frameColor,
//     required this.progress,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final ovalRect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);

//     // final borderPaint = Paint()
//     //   ..color = Colors.white.withOpacity(0.6)
//     //   ..style = PaintingStyle.stroke
//     //   ..strokeWidth = 2;
//     // canvas.drawOval(ovalRect, borderPaint);

//     final clampedProgress = progress.clamp(0.0, 1.0);
//     if (clampedProgress > 0) {
//       final progressPath = Path()..addOval(ovalRect);
//       final metric = progressPath.computeMetrics().first;
//       final segment = metric.extractPath(0, metric.length * clampedProgress);
//       final progressPaint = Paint()
//         ..color = frameColor
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 4
//         ..strokeCap = StrokeCap.round;
//       canvas.drawPath(segment, progressPaint);
//     }

//     // Draw guide lines (cross hair)
//     final guidePaint = Paint()
//       ..color = frameColor.withOpacity(0.5)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1;

//     // Horizontal line
//     canvas.drawLine(
//       Offset(center.dx - 20, center.dy),
//       Offset(center.dx + 20, center.dy),
//       guidePaint,
//     );

//     // Vertical line
//     canvas.drawLine(
//       Offset(center.dx, center.dy - 20),
//       Offset(center.dx, center.dy + 20),
//       guidePaint,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant _OvalFrameDarkenPainter oldDelegate) {
//     return oldDelegate.frameColor != frameColor ||
//         oldDelegate.progress != progress;
//   }
// }

class _InvertedOvalClipper extends CustomClipper<Path> {
  final double frameWidth;
  final double frameHeight;

  _InvertedOvalClipper({
    required this.frameWidth,
    required this.frameHeight,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: frameWidth,
      height: frameHeight,
    );

    // Add outer rectangle
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Subtract oval (inverted clip)
    path.addOval(ovalRect);
    path.fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
