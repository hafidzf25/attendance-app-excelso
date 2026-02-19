import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import 'api_service.dart';

/// Branch model
class Branch {
  final int id;
  final String name;
  final String code;
  final double lat;
  final double long;
  final double? distanceKm;

  Branch({
    required this.id,
    required this.name,
    required this.code,
    required this.lat,
    required this.long,
    this.distanceKm,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'] as String,
      name: json['name'] as String,
      lat: json['latitude'] is num
          ? json['latitude']
          : double.tryParse(json['latitude'].toString()),
      // (json['lat'] as num).toDouble(),
      long: json['longitude'] is num
          ? json['longitude']
          : double.tryParse(json['longitude'].toString()),
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'lat': lat,
      'long': long,
      'distance_km': distanceKm,
    };
  }
}

/// Attendance model
class AttendanceRecord {
  // final String id;
  // final String userId;
  final String? nik;
  final String? name;
  final double? similarity;
  // final DateTime checkInTime;
  // final DateTime? checkOutTime;
  // final String? photoPath;
  // final double? latitude;
  // final double? longitude;
  // final String status; // 'present', 'late', 'absent'

  AttendanceRecord({this.nik, this.name, this.similarity
      // required this.id,
      // required this.userId,
      // required this.checkInTime,
      // this.checkOutTime,
      // this.photoPath,
      // this.latitude,
      // this.longitude,
      // required this.status,
      });

  /// Convert ke JSON untuk API
  Map<String, dynamic> toJson() {
    return {
      // 'user_id': userId,
      // 'check_in_time': checkInTime.toIso8601String(),
      // 'check_out_time': checkOutTime?.toIso8601String(),
      // 'photo_path': photoPath,
      // 'latitude': latitude,
      // 'longitude': longitude,
      // 'status': status,
      'nik': nik,
      'name': name,
      'similarity': similarity,
    };
  }

  /// Parse dari API response
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      // id: json['id'] as String,
      // userId: json['user_id'] as String,
      // checkInTime: DateTime.parse(json['check_in_time'] as String),
      // checkOutTime: json['check_out_time'] != null
      //     ? DateTime.parse(json['check_out_time'] as String)
      //     : null,
      // photoPath: json['photo_path'] as String?,
      // latitude: (json['latitude'] as num?)?.toDouble(),
      // longitude: (json['longitude'] as num?)?.toDouble(),
      // status: json['status'] as String,
      nik: json['nik'] as String,
      name: json['name'] as String,
      similarity: json['similarity'] as double?,
    );
  }
}

/// Attendance repository - centralize semua attendance API calls
class AttendanceRepository {
  final ApiService _apiService = ApiService();
  
  // Cache untuk branch data
  List<Branch>? _cachedBranches;
  DateTime? _cacheTimestamp;
  final Duration _cacheExpiration = const Duration(minutes: 30);

  /// Get nearest branches within radius (dengan caching dan retry)
  Future<List<Branch>> getNearestBranches({
    required double latitude,
    required double longitude,
    double radius = 0.075, // km
    bool useCache = true,
  }) async {
    // Check cache dulu
    if (useCache && _isCacheValid()) {
      debugPrint("✅ Menggunakan cached branches");
      return _cachedBranches!;
    }

    // Jika cache expired, ambil dari API dengan retry
    return await _getNearestBranchesWithRetry(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }

  bool _isCacheValid() {
    if (_cachedBranches == null || _cacheTimestamp == null) {
      return false;
    }
    final elapsed = DateTime.now().difference(_cacheTimestamp!);
    return elapsed < _cacheExpiration;
  }

  Future<List<Branch>> _getNearestBranchesWithRetry({
    required double latitude,
    required double longitude,
    required double radius,
    int maxRetries = 3,
    int delaySeconds = 1,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint("📡 Attempt $attempt/$maxRetries: Fetching branches...");
        
        final response = await _apiService.get<List<Branch>>(
          '/branches/nearest',
          queryParameters: {
            'lat': latitude,
            'long': longitude,
          },
          options: Options(
            connectTimeout: const Duration(seconds: 45),
            receiveTimeout: const Duration(seconds: 45),
          ),
          dataParser: (json) {
            if (json is List) {
              debugPrint("Parsing branches: $json");
              return (json)
                  .map((item) => Branch.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
            return [];
          },
        );

        if (response.data == null) {
          throw ApiError(
            message: response.message ?? 'Failed to fetch nearest branches',
          );
        }

        // Cache berhasil
        _cachedBranches = response.data!;
        _cacheTimestamp = DateTime.now();
        
        debugPrint("✅ Berhasil load ${response.data!.length} branch (attempt $attempt)");
        return response.data!;
      } catch (e) {
        debugPrint('❌ Attempt $attempt failed: $e');
        
        if (attempt < maxRetries) {
          // Exponential backoff: 1s, 2s, 4s
          final waitSeconds = delaySeconds * (1 << (attempt - 1));
          debugPrint('⏳ Retry dalam ${waitSeconds}s...');
          await Future.delayed(Duration(seconds: waitSeconds));
        } else {
          // Semua retry gagal, throw error
          rethrow;
        }
      }
    }
    
    throw ApiError(
      message: 'Failed to fetch branches after $maxRetries attempts',
    );
  }

  /// Clear cache (call saat user logout atau refresh)
  void clearBranchCache() {
    _cachedBranches = null;
    _cacheTimestamp = null;
    debugPrint("🗑️ Branch cache cleared");
  }
  Future<AttendanceRecord> checkIn({
    required String photoPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          photoPath,
          filename: 'attendance.jpg',
        ),
      });

      final response = await _apiService.post<AttendanceRecord>(
        '/attendances',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        dataParser: (json) =>
            AttendanceRecord.fromJson(json as Map<String, dynamic>),
      );

      debugPrint("Checkin response: ${response.toString()}");

      if (!response.success || response.data == null) {
        throw ApiError(
          message: response.message ?? 'Check-in failed',
        );
      }

      // return response.message ?? 'Check-in successful'; // dummy, karena API belum siap, kita return message dulu
      return response.data!; // rill
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError(
        message: 'Error during check-in: $e',
        originalError: e,
      );
    }
  }

  /// Submit attendance check-out
  Future<AttendanceRecord> checkOut({
    required String attendanceId,
  }) async {
    try {
      final response = await _apiService.put<AttendanceRecord>(
        '/attendance/$attendanceId/check-out',
        data: {
          'check_out_time': DateTime.now().toIso8601String(),
        },
        dataParser: (json) =>
            AttendanceRecord.fromJson(json as Map<String, dynamic>),
      );

      if (!response.success || response.data == null) {
        throw ApiError(
          message: response.message ?? 'Check-out failed',
        );
      }

      return response.data!;
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError(
        message: 'Error during check-out: $e',
        originalError: e,
      );
    }
  }

  /// Get today's attendance
  Future<AttendanceRecord?> getTodayAttendance({
    required String userId,
  }) async {
    try {
      final response = await _apiService.get<AttendanceRecord>(
        '/attendance/today',
        queryParameters: {'user_id': userId},
        dataParser: (json) =>
            AttendanceRecord.fromJson(json as Map<String, dynamic>),
      );

      if (!response.success) {
        debugPrint('Error: ${response.message}');
        return null;
      }

      return response.data;
    } on ApiError catch (e) {
      debugPrint('Error getting today attendance: ${e.message}');
      rethrow;
    }
  }

  /// Get attendance history
  Future<List<AttendanceRecord>> getAttendanceHistory({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _apiService.get<List<AttendanceRecord>>(
        '/attendance/history',
        queryParameters: {
          'user_id': userId,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
        },
        dataParser: (json) {
          if (json is List) {
            return (json as List)
                .map((item) =>
                    AttendanceRecord.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return [];
        },
      );

      if (!response.success || response.data == null) {
        throw ApiError(
          message: response.message ?? 'Failed to fetch attendance history',
        );
      }

      return response.data!;
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError(
        message: 'Error fetching attendance history: $e',
        originalError: e,
      );
    }
  }
}
