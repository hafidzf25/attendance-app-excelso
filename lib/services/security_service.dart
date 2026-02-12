import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum SecurityStatus {
  safe,
  rooted,
  developerMode,
  mockLocation,
}

class SecurityService extends ChangeNotifier {
  static final SecurityService _instance = SecurityService._internal();
  static const platform =
      MethodChannel('com.example.absence_excelso/security');

  factory SecurityService() {
    return _instance;
  }

  SecurityService._internal();

  SecurityStatus _securityStatus = SecurityStatus.safe;
  String? _securityMessage;
  bool _isChecking = false;

  SecurityStatus get securityStatus => _securityStatus;
  String? get securityMessage => _securityMessage;
  bool get isChecking => _isChecking;
  bool get isSafe => _securityStatus == SecurityStatus.safe;

  /// Check semua security pada startup
  Future<SecurityStatus> checkDeviceSecurity() async {
    _isChecking = true;
    notifyListeners();

    try {
      // Check 1: Rooted/Jailbroken
      final bool isRooted = await _isDeviceRooted();
      if (isRooted) {
        _securityStatus = SecurityStatus.rooted;
        _securityMessage =
            'Device ini ter-root. Aplikasi tidak dapat dijalankan.';
        _isChecking = false;
        notifyListeners();
        return _securityStatus;
      }

      // Check 2: Developer Mode (Android only)
      final bool devMode = await _isDeveloperModeEnabled();
      if (devMode) {
        _securityStatus = SecurityStatus.developerMode;
        _securityMessage =
            'Mode Pengembang aktif. Aplikasi tidak dapat dijalankan.';
        _isChecking = false;
        notifyListeners();
        return _securityStatus;
      }

      // Check 3: Mock Location
      final bool mockLocation = await _isMockLocationEnabled();
      if (mockLocation) {
        _securityStatus = SecurityStatus.mockLocation;
        _securityMessage =
            'Mock Location aktif. Aplikasi tidak dapat dijalankan.';
        _isChecking = false;
        notifyListeners();
        return _securityStatus;
      }

      _securityStatus = SecurityStatus.safe;
      _securityMessage = null;
      _isChecking = false;
      notifyListeners();
      return _securityStatus;
    } catch (e) {
      _securityMessage = 'Error checking security: $e';
      _isChecking = false;
      notifyListeners();
      return SecurityStatus.safe; // Default safe jika error
    }
  }

  /// Cek apakah device ter-root (Android only)
  Future<bool> _isDeviceRooted() async {
    try {
      final bool isRooted =
          await platform.invokeMethod('isDeviceRooted') as bool;
      return isRooted;
    } on PlatformException catch (e) {
      debugPrint('Failed to check root status: ${e.message}');
      return false;
    }
  }

  /// Cek apakah Developer Mode aktif (Android only)
  Future<bool> _isDeveloperModeEnabled() async {
    try {
      final bool isDeveloperMode =
          await platform.invokeMethod('isDeveloperModeEnabled') as bool;
      return isDeveloperMode;
    } on PlatformException catch (e) {
      debugPrint('Failed to check developer mode: ${e.message}');
      return false;
    }
  }

  /// Cek apakah Mock Location aktif (Android only)
  Future<bool> _isMockLocationEnabled() async {
    try {
      final bool isMockLocation =
          await platform.invokeMethod('isMockLocationEnabled') as bool;
      return isMockLocation;
    } on PlatformException catch (e) {
      debugPrint('Failed to check mock location: ${e.message}');
      return false;
    }
  }

  /// Reset status
  void reset() {
    _securityStatus = SecurityStatus.safe;
    _securityMessage = null;
    _isChecking = false;
    notifyListeners();
  }
}
