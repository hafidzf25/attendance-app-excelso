import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:typed_data';
import 'dart:ui';

class FaceDetectionService {
  static final FaceDetectionService _instance = FaceDetectionService._internal();

  factory FaceDetectionService() {
    return _instance;
  }

  FaceDetectionService._internal();

  late FaceDetector _faceDetector;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize face detector
  Future<void> initialize() async {
    try {
      // Create face detector dengan high accuracy
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableClassification: true,
          enableLandmarks: true,
          enableTracking: true,
        ),
      );
      _isInitialized = true;
      debugPrint('✓ FaceDetectionService initialized');
    } catch (e) {
      debugPrint('✗ Error initializing FaceDetectionService: $e');
      _isInitialized = false;
    }
  }

  /// Detect faces dari CameraImage
  Future<List<Face>> detectFaces(CameraImage image) async {
    if (!_isInitialized) {
      return [];
    }

    try {
      // Convert CameraImage to InputImage untuk ML Kit
      final inputImage = _cameraImageToInputImage(image);
      if (inputImage == null) return [];

      // Process image untuk detect faces
      final faces = await _faceDetector.processImage(inputImage);

      return faces;
    } catch (e) {
      debugPrint('Error detecting faces: $e');
      return [];
    }
  }

  /// Check apakah ada valid face (face terdeteksi dengan good quality)
  bool hasValidFace(List<Face> faces) {
    if (faces.isEmpty) return false;

    // Require minimal 1 face dengan landmark terdeteksi
    return faces.any((face) {
      // Check apakah ada landmark (mata, hidung, mulut terdeteksi)
      final hasLandmarks = face.landmarks.isNotEmpty;

      // Check apakah head angle tidak terlalu miring (relaxed to 45 degrees)
      final headEulerAngleY = face.headEulerAngleY ?? 0;
      const maxHeadAngle = 45; // Max 45 degrees rotation

      return hasLandmarks && headEulerAngleY.abs() < maxHeadAngle;
    });
  }

  /// Get best face (terbesar/paling depan)
  Face? getBestFace(List<Face> faces) {
    if (faces.isEmpty) return null;

    // Sort by bounding box area (largest first = closest to camera)
    faces.sort((a, b) {
      final areaA = a.boundingBox.width * a.boundingBox.height;
      final areaB = b.boundingBox.width * b.boundingBox.height;
      return areaB.compareTo(areaA);
    });

    return faces.first;
  }

  /// Convert CameraImage ke InputImage untuk ML Kit
  InputImage? _cameraImageToInputImage(CameraImage image) {
    try {
      final planes = image.planes;
      if (planes.isEmpty) return null;

      const InputImageRotation imageRotation = InputImageRotation.rotation0deg;
      final inputFormat = InputImageFormatValue.fromRawValue(image.format.raw);
      if (inputFormat == null) {
        debugPrint('Unsupported image format: ${image.format.raw}');
        return null;
      }
      if (inputFormat != InputImageFormat.yuv_420_888 &&
          inputFormat != InputImageFormat.nv21 &&
          inputFormat != InputImageFormat.yv12) {
        debugPrint('Unsupported ML Kit format: $inputFormat (${image.format.raw})');
        return null;
      }

      Uint8List bytes;
      InputImageFormat formatForMlKit = inputFormat;
      int bytesPerRow = planes.first.bytesPerRow;

      if (inputFormat == InputImageFormat.yuv_420_888) {
        // ML Kit Android expects NV21; convert from YUV_420_888.
        bytes = _yuv420ToNv21(image);
        formatForMlKit = InputImageFormat.nv21;
        bytesPerRow = image.width;
      } else {
        final WriteBuffer buffer = WriteBuffer();
        for (final Plane plane in planes) {
          buffer.putUint8List(plane.bytes);
        }
        bytes = buffer.done().buffer.asUint8List();
      }

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: imageRotation,
          format: formatForMlKit,
          bytesPerRow: bytesPerRow,
        ),
      );

      return inputImage;
    } catch (e) {
      debugPrint('Error converting CameraImage to InputImage: $e');
      return null;
    }
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = ySize ~/ 2;
    final Uint8List nv21 = Uint8List(ySize + uvSize);

    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    // Copy Y plane.
    int yIndex = 0;
    final int yRowStride = yPlane.bytesPerRow;
    for (int row = 0; row < height; row++) {
      final int rowStart = row * yRowStride;
      nv21.setRange(yIndex, yIndex + width, yPlane.bytes, rowStart);
      yIndex += width;
    }

    // Interleave V and U to NV21 format.
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 1;
    int uvIndex = ySize;
    for (int row = 0; row < height ~/ 2; row++) {
      for (int col = 0; col < width ~/ 2; col++) {
        final int uvOffset = row * uvRowStride + col * uvPixelStride;
        nv21[uvIndex++] = vPlane.bytes[uvOffset];
        nv21[uvIndex++] = uPlane.bytes[uvOffset];
      }
    }

    return nv21;
  }

  /// Dispose face detector
  Future<void> dispose() async {
    try {
      await _faceDetector.close();
      _isInitialized = false;
    } catch (e) {
      debugPrint('Error disposing FaceDetectionService: $e');
    }
  }
}

/// Extension untuk Face properties
extension FaceProperties on Face {
  /// Get face center point (untuk positioning UI)
  Offset getFaceCenter() {
    final box = boundingBox;
    return Offset(
      box.left + box.width / 2,
      box.top + box.height / 2,
    );
  }

  /// Get face size ratio (0 to 1, where 1 = full screen)
  double getFaceSize(double screenWidth, double screenHeight) {
    final faceArea = boundingBox.width * boundingBox.height;
    final screenArea = screenWidth * screenHeight;
    return (faceArea / screenArea).clamp(0, 1);
  }

  /// Check apakah face positioned well di center
  bool isCentered(double screenWidth, double screenHeight, {double tolerance = 0.2}) {
    final center = getFaceCenter();
    final screenCenter = Offset(screenWidth / 2, screenHeight / 2);

    final dx = (center.dx - screenCenter.dx).abs() / screenWidth;
    final dy = (center.dy - screenCenter.dy).abs() / screenHeight;

    return dx < tolerance && dy < tolerance;
  }

  /// Get face quality score (0 to 100)
  int getQualityScore(double screenWidth, double screenHeight) {
    int score = 50; // Base score

    // +20 jika face di center
    if (isCentered(screenWidth, screenHeight)) {
      score += 20;
    }

    // +20 jika ada landmarks
    if (landmarks.isNotEmpty) {
      score += 20;
    }

    // +10 jika head angle baik
    final headEulerAngleY = this.headEulerAngleY ?? 0;
    if (headEulerAngleY.abs() < 15) {
      score += 10;
    }

    return score.clamp(0, 100);
  }
}
