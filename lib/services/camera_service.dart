import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as pm;

class CameraService extends ChangeNotifier {
  static final CameraService _instance = CameraService._internal();

  factory CameraService() {
    return _instance;
  }

  CameraService._internal();

  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isDisposed = false;

  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  /// Safe notify listeners - check if disposed first
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
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

      // Request storage permission untuk save photo ke Downloads (optional, tidak crash jika denied)
      await pm.Permission.storage.request();

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

      // Initialize dengan front camera - enableAudio: false untuk tidak minta audio permission
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false, // Gaada audio permission minta
      );

      await _cameraController!.initialize();
      _isInitialized = true;
      _errorMessage = null;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error initialize camera: $e';
      _isInitialized = false;
      _safeNotifyListeners();
      return false;
    }
  }

  /// Capture photo dan save ke public Pictures folder (accessible dari galeri)
  /// Flip image horizontal untuk normalize front camera mirror effect
  Future<String?> capturePhoto() async {
    try {
      if (_cameraController == null || !_isInitialized) {
        _errorMessage = 'Camera belum initialized';
        return null;
      }

      // Capture photo
      final XFile photo = await _cameraController!.takePicture();
      
      // Read image file
      final imageBytes = await photo.readAsBytes();
      var image = img.decodeImage(imageBytes);
      
      if (image == null) {
        _errorMessage = 'Error decoding image';
        return null;
      }
      
      // Flip horizontal untuk normalize front camera mirror effect
      image = img.flipHorizontal(image);
      
      // Get external storage (public folder, bisa diakses galeri)
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        _errorMessage = 'Storage tidak tersedia';
        return null;
      }
      
      // Create Attendance folder di Pictures
      // Navigate up to /storage/emulated/0 from app-specific folder
      final String publicPath = externalDir.path.replaceAll('/Android/data/${_getPackageName()}/files', '');
      final Directory attendanceDir = Directory('$publicPath/Pictures/Attendance');
      
      if (!await attendanceDir.exists()) {
        await attendanceDir.create(recursive: true);
      }
      
      // Create filename dengan timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'attendance_$timestamp.jpg';
      final String filePath = '${attendanceDir.path}/$fileName';
      
      // Save flipped image ke public folder
      final File savedFile = File(filePath);
      await savedFile.writeAsBytes(img.encodeJpg(image));
      
      return savedFile.path;
    } catch (e) {
      _errorMessage = 'Error capturing photo: $e';
      _safeNotifyListeners();
      return null;
    }
  }
  
  /// Helper untuk get package name
  String _getPackageName() {
    // Default package name, bisa juga dari context tapi kita hardcode aja
    return 'com.example.absence_excelso';
  }

  /// Cleanup camera controller
  Future<void> dispose() async {
    await _cameraController?.dispose();
    _cameraController = null;
    _isInitialized = false;
    _isDisposed = true;
    super.dispose();
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
