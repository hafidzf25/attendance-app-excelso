import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as pm;

import '../utils/image_utils.dart';

class CameraService extends ChangeNotifier {
  static final CameraService _instance = CameraService._internal();

  // Output image resolution constants
  static const int OUTPUT_WIDTH = 480;
  static const int OUTPUT_HEIGHT = 512;

  factory CameraService() {
    return _instance;
  }

  CameraService._internal();

  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  bool _isInitialized = false;
  String? _errorMessage;

  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  /// Safe notify listeners - jangan throw jika sudah disposed
  void _safeNotifyListeners() {
    try {
      notifyListeners();
    } catch (e) {
      // Silently ignore jika sudah disposed atau error lain
      debugPrint('Notify listeners error (likely disposed): $e');
    }
  }

  /// Initialize camera (call saat app start atau sebelum buka camera page)
  Future<bool> initializeCamera() async {
    try {
      // Request camera permission only (jangan audio)
      final cameraStatus = await pm.Permission.camera.request();
      if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
        _errorMessage = 'Izin kamera ditolak. Silakan enable di pengaturan.';
        _safeNotifyListeners();
        return false;
      }

      // Auto simpan ke storage publik dinonaktifkan
      // await pm.Permission.storage.request();

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _errorMessage = 'Tidak ada kamera tersedia';
        _safeNotifyListeners();
        return false;
      }

      // Get front camera untuk selfie/face capture
      final frontCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras[0],
      );

      // Try to initialize dengan fallback untuk resolution preset
      // Beberapa device tidak support ResolutionPreset.high
      // Fallback order: high → medium → low → veryLow (last resort)
      final resolutionPresets = [
        ResolutionPreset.high,
        ResolutionPreset.medium,
        ResolutionPreset.low,
      ];

      String? lastError;
      for (int i = 0; i < resolutionPresets.length; i++) {
        final preset = resolutionPresets[i];
        try {
          debugPrint('Attempting camera initialization with preset: $preset');

          _cameraController = CameraController(
            frontCamera,
            preset,
            enableAudio: false, // Gaada audio permission minta
            imageFormatGroup: ImageFormatGroup.yuv420,
          );

          await _cameraController!.initialize();

          // Small delay untuk ensure initialization selesai
          await Future.delayed(const Duration(milliseconds: 200));

          // Disable flash
          try {
            await _cameraController!.setFlashMode(FlashMode.off);
            await _cameraController!.setExposureMode(ExposureMode.auto);
            final min = await _cameraController!.getMinExposureOffset();

            final max = await _cameraController!.getMaxExposureOffset();

            final optimalExposure = (max * 0.6).clamp(min, max);

            await _cameraController!.setExposureOffset(optimalExposure);
          } catch (e) {
            debugPrint('Warning: Could not disable flash: $e');
          }

          _isInitialized = true;
          _errorMessage = null;
          _safeNotifyListeners();
          debugPrint('✓ Camera initialized successfully with preset: $preset');
          return true;
        } catch (e) {
          lastError = e.toString();
          debugPrint('✗ Failed to initialize with preset $preset: $e');

          // Dispose controller dengan proper cleanup
          try {
            await _cameraController?.dispose();
          } catch (disposeError) {
            debugPrint('Error disposing controller: $disposeError');
          }
          _cameraController = null;

          // Jika bukan preset terakhir, lanjut ke next preset
          if (i < resolutionPresets.length - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
        }
      }

      // Jika semua preset gagal
      _errorMessage =
          'Tidak dapat menginisialisasi kamera. Device mungkin tidak kompatibel.';
      _isInitialized = false;
      _safeNotifyListeners();
      debugPrint('✗ All resolution presets failed. Last error: $lastError');
      return false;
    } catch (e) {
      _errorMessage = 'Error initialize camera: $e';
      _isInitialized = false;
      _safeNotifyListeners();
      debugPrint('✗ Critical error during camera initialization: $e');
      return false;
    }
  }

  /// Capture photo dan save ke public Pictures folder (accessible dari galeri)
  /// Flip image horizontal untuk normalize front camera mirror effect
  Future<String?> capturePhoto() async {
    try {
      final controller = _cameraController;
      if (controller == null ||
          !_isInitialized ||
          !controller.value.isInitialized) {
        _errorMessage = 'Camera belum initialized';
        return null;
      }

      if (controller.value.isTakingPicture) {
        _errorMessage = 'Camera sedang mengambil foto';
        return null;
      }

      // Image stream sudah distop dari caller (CameraPage) sebelum capture
      // supaya shutter lebih responsif dan tidak menambah delay.

      // Capture photo
      final XFile photo = await controller.takePicture();

      // Read and process image
      final imageBytes = await photo.readAsBytes();
      if (imageBytes.isEmpty) {
        _errorMessage = 'Photo bytes empty';
        return null;
      }

      var image = ImageUtils.decodeFromBytes(imageBytes);

      if (image == null) {
        _errorMessage = 'Error decoding image';
        return null;
      }

      // Flip horizontal untuk normalize front camera mirror effect
      image = ImageUtils.flipHorizontal(image);
      if (image == null) {
        _errorMessage = 'Error flipping image';
        return null;
      }

      // Detect device orientation dari camera sensor
      // Front camera di portrait: width < height
      // Front camera di landscape: width > height
      bool isLandscape = image.width > image.height;
      if (isLandscape) {
        // Rotate 90 derajat clockwise untuk landscape
        image = ImageUtils.rotateClockwise(image);
        if (image == null) {
          _errorMessage = 'Error rotating image';
          return null;
        }
      }

      // Fit & crop image ke resolusi 480x512 (no distortion)
      // - Resize width ke 480 maintaining aspect ratio
      // - Crop height ke 512 dari center/top
      image = ImageUtils.fitAndCrop(image, OUTPUT_WIDTH, OUTPUT_HEIGHT);
      if (image == null) {
        _errorMessage = 'Error processing image';
        return null;
      }

      // Auto simpan ke galeri/public folder dinonaktifkan
      // final Directory? externalDir = await getExternalStorageDirectory();
      // if (externalDir == null) {
      //   _errorMessage = 'Storage tidak tersedia';
      //   return null;
      // }
      // final String publicPath = externalDir.path
      //     .replaceAll('/Android/data/${_getPackageName()}/files', '');
      // final Directory attendanceDir = Directory('$publicPath/Pictures/Attendance');
      // if (!await attendanceDir.exists()) {
      //   await attendanceDir.create(recursive: true);
      // }
      // final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      // final String fileName = 'attendance_$timestamp.jpg';
      // final String filePath = '${attendanceDir.path}/$fileName';
      // final File savedFile = File(filePath);
      // await savedFile.writeAsBytes(ImageUtils.encodeToJpg(image));
      // return savedFile.path;

      // Tetap simpan hasil proses ke file temporary bawaan camera
      final File tempFile = File(photo.path);
      final encodedBytes = ImageUtils.encodeToJpg(image);
      if (encodedBytes.isEmpty) {
        _errorMessage = 'Error encoding image to JPG';
        return null;
      }

      await tempFile.writeAsBytes(encodedBytes);
      return tempFile.path;
    } catch (e) {
      _errorMessage = 'Error capturing photo: $e';
      _safeNotifyListeners();
      debugPrint('Capture photo error: $e');
      return null;
    }
  }

  /// Cleanup camera controller (tidak permanent dispose ChangeNotifier)
  /// Agar bisa reinitialize untuk multiple camera sessions (enrollment)
  ///
  /// NOTE: Sengaja TIDAK call super.dispose() agar singleton tetap reusable
  // ignore: must_call_super
  Future<void> dispose() async {
    try {
      await _cameraController?.dispose();
    } catch (e) {
      debugPrint('Error disposing camera controller: $e');
    }
    _cameraController = null;
    _isInitialized = false;

    // Notify listeners tentang perubahan state
    try {
      notifyListeners();
    } catch (e) {
      // Silently ignore
      debugPrint('Notify listeners error: $e');
    }

    // PENTING: JANGAN call super.dispose() untuk singleton yang reusable
    // Walaupun ada @mustCallSuper annotation, singleton harus tetap "alive"
    // agar bisa dipakai lagi (contoh: enrollment multi-shot loop)
    // Super.dispose() akan permanent mark ChangeNotifier sebagai disposed
  }

  /// Get front camera
  CameraDescription? getFrontCamera() {
    if (_cameras.isEmpty) return null;
    try {
      return _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras[0],
      );
    } catch (e) {
      return _cameras[0];
    }
  }

  /// Get rear camera
  CameraDescription? getRearCamera() {
    if (_cameras.isEmpty) return null;
    try {
      return _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras[0],
      );
    } catch (e) {
      return _cameras[0];
    }
  }
}
