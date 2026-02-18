import 'package:absence_excelso/constants/colors.dart';
import 'package:absence_excelso/pages/photo_review_page.dart';
import 'package:absence_excelso/services/camera_service.dart';
import 'package:absence_excelso/services/face_detection_service.dart';
import 'package:absence_excelso/utils/image_utils.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final CameraService _cameraService = CameraService();
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  
  bool _isLoading = true;
  Uint8List? _cropPreview;
  bool _isProcessing = false;
  int _frameCounter = 0;
  
  // Face detection state
  bool _faceDetected = false;
  int _faceQualityScore = 0;
  String _faceStatus = 'Mendeteksi wajah...';

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
      final faces = await _faceDetectionService.detectFaces(image);
      final hasValidFace = _faceDetectionService.hasValidFace(faces);
      
      if (mounted) {
        int qualityScore = 0;
        String statusText = 'Wajah tidak terdeteksi';
        
        if (hasValidFace) {
          final bestFace = _faceDetectionService.getBestFace(faces);
          if (bestFace != null) {
            qualityScore = bestFace.getQualityScore(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            );
            
            if (qualityScore >= 80) {
              statusText = 'Sempurna! 😊';
            } else if (qualityScore >= 60) {
              statusText = 'Bagus, posisikan lebih baik';
            } else {
              statusText = 'Posisikan wajah di center';
            }
          }
        }
        
        setState(() {
          _faceDetected = hasValidFace;
          _faceQualityScore = qualityScore;
          _faceStatus = statusText;
        });
      }
      
      final bytes = _concatenatePlanes(image);
      if (bytes.isEmpty) return;
      
      final decoded = img.decodeImage(bytes);
      if (decoded != null && mounted) {
        final cropped = ImageUtils.fitAndCrop(decoded, 480, 512);
        if (cropped != null) {
          final previewResized = ImageUtils.resize(cropped, 240, 256);
          if (previewResized != null) {
            final preview = ImageUtils.encodeToJpg(previewResized, 50);
            if (mounted) {
              setState(() {
                _cropPreview = Uint8List.fromList(preview);
              });
            }
          }
        }
      }
      
    } catch (e) {
      debugPrint('Preview error: $e');
    }
  }

  Uint8List _concatenatePlanes(CameraImage image) {
    final BytesBuilder allBytes = BytesBuilder(copy: false);
    for (final Plane plane in image.planes) {
      allBytes.add(plane.bytes);
    }
    return allBytes.toBytes();
  }

  Future<void> _capturePhoto() async {
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

    if (_faceQualityScore < 50) {
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
    } finally {
      final controller = _cameraService.cameraController;
      if (mounted && controller != null && !controller.value.isStreamingImages) {
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
    if (_cameraService.cameraController == null || !_cameraService.isInitialized) {
      return Center(
        child: Text(
          _cameraService.errorMessage ?? 'Camera not available',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      );
    }

    return Stack(
      children: [
        CameraPreview(_cameraService.cameraController!),
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _faceDetected ? Colors.green.withOpacity(0.7) : Colors.black54,
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
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AspectRatio(
                      aspectRatio: 480 / 512,
                      child: Stack(
                        children: [
                          if (_cropPreview != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(_cropPreview!, fit: BoxFit.cover),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          CustomPaint(
                            painter: _OutsideFrameDarkenPainter(frameColor: AppColors.primary),
                            size: Size.infinite,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _faceQualityScore / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation(
                          _faceDetected && _faceQualityScore >= 80
                              ? Colors.green
                              : _faceDetected && _faceQualityScore >= 60
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kualitas Wajah: $_faceQualityScore/100',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                      backgroundColor: _faceDetected && _faceQualityScore >= 50
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
  }
}

class _OutsideFrameDarkenPainter extends CustomPainter {
  final Color frameColor;

  _OutsideFrameDarkenPainter({required this.frameColor});

  @override
  void paint(Canvas canvas, Size size) {
    final frameRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final frameRRect = RRect.fromRectAndRadius(frameRect, const Radius.circular(16));

    final fullPath = Path()..addRect(frameRect);
    final framePath = Path()..addRRect(frameRRect);
    final outsidePath = Path.combine(PathOperation.difference, fullPath, framePath);

    final darkPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(outsidePath, darkPaint);

    final borderPaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(frameRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
