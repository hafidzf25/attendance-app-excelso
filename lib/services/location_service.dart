import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as pm;

class LocationService extends ChangeNotifier {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  Position? _currentPosition;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isMockLocation = false;

  Position? get currentPosition => _currentPosition;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isMockLocation => _isMockLocation;

  /// Request location permission dan ambil lokasi
  /// Dipanggil saat app startup
  Future<bool> requestLocationPermissionAndGetLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Request permission
      final pm.PermissionStatus status = await pm.Permission.location.request();

      if (status.isDenied) {
        _errorMessage = 'Permission lokasi ditolak';
        _isLoading = false;
        notifyListeners();
        return false;
      } else if (status.isPermanentlyDenied) {
        _errorMessage = 'Permission lokasi ditolak selamanya';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get location
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Ambil lokasi terbaru (untuk refresh)
  Future<bool> getCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset data
  void reset() {
    _currentPosition = null;
    _errorMessage = null;
    _isLoading = false;
    _isMockLocation = false;
    notifyListeners();
  }

  /// Cek apakah lokasi adalah mock/fake GPS
  /// Fake GPS biasanya memiliki akurasi > 100 meter
  bool checkIfMockLocation() {
    if (_currentPosition == null) return false;

    // Jika akurasi > 100 meter, indikasi mock location
    _isMockLocation = _currentPosition!.accuracy > 100;
    notifyListeners();
    return _isMockLocation;
  }
}
