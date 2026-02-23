import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:typed_data';
import 'dart:ui';

class FaceDetectionService {
  static final FaceDetectionService _instance =
      FaceDetectionService._internal();

  factory FaceDetectionService() {
    return _instance;
  }

  FaceDetectionService._internal();

  late FaceDetector _faceDetector;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Offset? _lastFaceCenter;
  DateTime? _lastFaceTime;

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
      final brightness = calculateBrightness(image);

      if (brightness < 80 || brightness > 200) {
        return [];
      }

      // Convert CameraImage to InputImage untuk ML Kit
      final inputImage = _cameraImageToInputImage(image);
      if (inputImage == null) return [];

      // Process image untuk detect faces
      final faces = await _faceDetector.processImage(inputImage);

      // Filter wajah palsu (refleksi/shadow) dari hasil deteksi
      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();
      final filteredFaces = _filterFakeFaces(faces, imageWidth, imageHeight);

      return filteredFaces;
    } catch (e) {
      debugPrint('Error detecting faces: $e');
      return [];
    }
  }

  /// Filter deteksi wajah palsu (refleksi/shadow)
  /// Hanya retain wajah yang memiliki area signifikan, jarak dari utama > threshold, dan landmarks
  List<Face> _filterFakeFaces(
      List<Face> faces, double imgWidth, double imgHeight) {
    if (faces.length <= 1) {
      return faces;
    }

    // Sort by size descending (terbesar = asli)
    faces.sort((a, b) {
      final areaA = a.boundingBox.width * a.boundingBox.height;
      final areaB = b.boundingBox.width * b.boundingBox.height;
      return areaB.compareTo(areaA);
    });

    final largest = faces.first;
    final largestArea = largest.boundingBox.width * largest.boundingBox.height;
    final largestCenter = Offset(
      largest.boundingBox.left + largest.boundingBox.width / 2,
      largest.boundingBox.top + largest.boundingBox.height / 2,
    );

    // Retain wajah yang: area >= 40% terbesar, jarak > 120px, dan ada landmarks
    return faces.where((face) {
      if (face == largest) return true;

      final faceArea = face.boundingBox.width * face.boundingBox.height;
      final areaRatio = faceArea / largestArea;

      final faceCenter = Offset(
        face.boundingBox.left + face.boundingBox.width / 2,
        face.boundingBox.top + face.boundingBox.height / 2,
      );
      final distance = (largestCenter - faceCenter).distance;

      final hasLandmarks = face.landmarks.isNotEmpty;

      return areaRatio >= 0.4 && distance > 120 && hasLandmarks;
    }).toList();
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

    final imageCenterX =
        faces.first.boundingBox.left + faces.first.boundingBox.width / 2;

    faces.sort((a, b) {
      final areaA = a.boundingBox.width * a.boundingBox.height;

      final areaB = b.boundingBox.width * b.boundingBox.height;

      final centerA = a.getFaceCenter();
      final centerB = b.getFaceCenter();

      final distA = (centerA.dx - imageCenterX).abs();
      final distB = (centerB.dx - imageCenterX).abs();

      if ((areaB - areaA).abs() > 1000) {
        return areaB.compareTo(areaA);
      }

      return distA.compareTo(distB);
    });

    return faces.first;
  }

  double calculateBrightness(CameraImage image) {
    final plane = image.planes[0];

    int sum = 0;

    for (int i = 0; i < plane.bytes.length; i += 20) {
      sum += plane.bytes[i];
    }

    return sum / (plane.bytes.length / 20);
  }

  bool isFaceStable(Face face) {
    final now = DateTime.now();
    final center = face.getFaceCenter();

    if (_lastFaceCenter == null || _lastFaceTime == null) {
      _lastFaceCenter = center;
      _lastFaceTime = now;
      return false;
    }

    final dt = now.difference(_lastFaceTime!).inMilliseconds;
    if (dt > 1200) {
      _lastFaceCenter = center;
      _lastFaceTime = now;
      return false;
    }

    final dx = (center.dx - _lastFaceCenter!.dx).abs();
    final dy = (center.dy - _lastFaceCenter!.dy).abs();

    _lastFaceCenter = center;
    _lastFaceTime = now;

    return dx < 16 && dy < 16;
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
        debugPrint(
            'Unsupported ML Kit format: $inputFormat (${image.format.raw})');
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
  bool isCentered(double screenWidth, double screenHeight,
      {double tolerance = 0.2}) {
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
