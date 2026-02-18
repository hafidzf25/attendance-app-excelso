import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/api_error.dart';
import 'api_service.dart';

/// Attendance model
class AttendanceRecord {
  final String id;
  final String userId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String? photoPath;
  final double? latitude;
  final double? longitude;
  final String status; // 'present', 'late', 'absent'

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.checkInTime,
    this.checkOutTime,
    this.photoPath,
    this.latitude,
    this.longitude,
    required this.status,
  });

  /// Convert ke JSON untuk API
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'photo_path': photoPath,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }

  /// Parse dari API response
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      checkInTime: DateTime.parse(json['check_in_time'] as String),
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'] as String)
          : null,
      photoPath: json['photo_path'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: json['status'] as String,
    );
  }
}

/// Attendance repository - centralize semua attendance API calls
class AttendanceRepository {
  final ApiService _apiService = ApiService();

  /// Submit attendance check-in
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
        dataParser: (json) => AttendanceRecord.fromJson(json as Map<String, dynamic>),
      );

      if (!response.success || response.data == null) {
        throw ApiError(
          message: response.message ?? 'Check-in failed',
        );
      }

      return response.data!;
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
        dataParser: (json) => AttendanceRecord.fromJson(json as Map<String, dynamic>),
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
        dataParser: (json) => AttendanceRecord.fromJson(json as Map<String, dynamic>),
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
                .map((item) => AttendanceRecord.fromJson(item as Map<String, dynamic>))
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
