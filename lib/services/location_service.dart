import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
      // Check permission status first
      final permStatus = await pm.Permission.location.status;
      
      // If permission belum pernah diminta, request dulu
      if (permStatus.isDenied) {
        debugPrint("Permission not requested yet, requesting...");
        final pm.PermissionStatus status = await pm.Permission.location.request();
        
        if (status.isDenied || status.isPermanentlyDenied) {
          _errorMessage = 'Permission lokasi ditolak';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else if (permStatus.isPermanentlyDenied) {
        _errorMessage = 'Anda akan diarahkan untuk mengaktifkan permission lokasi ...';
        _isLoading = false;
        notifyListeners();
        await pm.openAppSettings();
        await Future.delayed(const Duration(seconds: 2));
        
        if (!await pm.Permission.location.isGranted) {
          _errorMessage = 'Akses lokasi masih belum diberikan. Silakan enable di pengaturan.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // Now try to get location
      return await _getLocationAndUpdateUI();
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Helper method: Ambil lokasi dan update UI
  Future<bool> _getLocationAndUpdateUI() async {
    _isLoading = true;
    _errorMessage = null;
    _isMockLocation = false;
    notifyListeners();

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Check if location is mocked
      if (position.isMocked) {
        _isMockLocation = true;
        _errorMessage = 'Mock Location terdeteksi. Silakan matikan GPS Mock di pengaturan.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentPosition = position;
      _isMockLocation = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error ambil lokasi: $e';
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
}
