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

/// Branch model
class Shift {
  final int id;
  final int ordering;
  final DateTime startTime;
  final DateTime endTime;

  Shift({
    required this.id,
    required this.ordering,
    required this.startTime,
    required this.endTime,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      ordering: json['ordering'] is int
          ? json['ordering']
          : int.tryParse(json['ordering'].toString()) ?? 0,
      startTime: _parseTime(json['startTime'] ?? json['start_time']),
      endTime: _parseTime(json['endTime'] ?? json['end_time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ordering': ordering,
      'startTime': _formatTime(startTime),
      'endTime': _formatTime(endTime),
    };
  }

  static DateTime _parseTime(dynamic value) {
    final now = DateTime.now();

    if (value is DateTime) {
      return DateTime(
        now.year,
        now.month,
        now.day,
        value.hour,
        value.minute,
        value.second,
      );
    }

    final raw = value?.toString() ?? '';
    final match = RegExp(r'(\d{2}):(\d{2}):(\d{2})').firstMatch(raw);

    if (match != null) {
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    }

    throw FormatException('Invalid time format: $raw');
  }

  /// Format time-only untuk kirim ke backend
  static String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')}:"
        "${dateTime.second.toString().padLeft(2, '0')}";
  }
}

class DateFormatter {
  static String toTimeHM(String isoString) {
    final dt = DateTime.parse(isoString);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  static String toDateTimeHMS(String isoString) {
    final dt = DateTime.parse(isoString).toLocal();

    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');

    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');

    return "$year-$month-$day $hour:$minute:$second";
  }
}

/// Attendance model
class AttendanceRecord {
  // final String id;
  // final String userId;
  final String? employeeNumber;
  final String? employeeName;
  // final double? similarity;
  final String? branch;
  final String? type;
  final String? shiftStart;
  final String? shifEnd;
  final String? clockAt;
  // final DateTime checkInTime;
  // final DateTime? checkOutTime;
  // final String? photoPath;
  // final double? latitude;
  // final double? longitude;
  // final String status; // 'present', 'late', 'absent'

  AttendanceRecord({
    this.employeeNumber,
    this.employeeName,
    // this.similarity,
    this.branch,
    this.type,
    this.shiftStart,
    this.shifEnd,
    this.clockAt,
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
      'employeeNumber': employeeNumber,
      'employeeName': employeeName,
      // 'similarity': similarity,
      'branch': branch,
      'type': type,
      'shiftStart': shiftStart,
      'shifEnd': shifEnd,
      'clockAt': clockAt,
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
      employeeNumber: json['employeeNumber'] as String,
      employeeName: json['employeeName'] as String,
      // similarity: json['similarity'] as double?,
      branch: json['branch'] as String,
      type: json['type'] as String,
      shiftStart: DateFormatter.toTimeHM(json["shiftStart"]!),
      shifEnd: DateFormatter.toTimeHM(json["shifEnd"]!),
      clockAt: DateFormatter.toDateTimeHMS(json["clockAt"]!),
    );
  }
}

/// Attendance repository - centralize semua attendance API calls
class AttendanceRepository {
  final ApiService _apiService = ApiService();

  /// Submit attendance check-in
  Future<AttendanceRecord> checkIn({
    required String photoPath,
    required double latitude,
    required double longitude,
    required String type,
    required int shiftId,
    required String branchCode,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          photoPath,
          filename: 'attendance.jpg',
        ),
        'latitude': latitude,
        'longitude': longitude,
        'type': type,
        'shiftId': shiftId,
        'branchCode': branchCode,
      });

      final response = await _apiService.post<AttendanceRecord>(
        '/attendances',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        dataParser: (json) =>
            AttendanceRecord.fromJson(json as Map<String, dynamic>),
      );

      debugPrint("Checkin response: ${response.toString()}");

      // if (!response.success || response.data == null) {
      if (response.data == null) {
        throw ApiError(
          message: response.message ?? 'Check-in failed',
        );
      }

      // return response.message ?? 'Check-in successful'; // dummy, karena API belum siap, kita return message dulu
      debugPrint("${response.rawData}");
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

  /// Get nearest branches within radius
  Future<List<Branch>> getNearestBranches({
    required double latitude,
    required double longitude,
    double radius = 0.075, // km
  }) async {
    try {
      final response = await _apiService.get<List<Branch>>(
        '/branches/nearest',
        queryParameters: {
          'lat': latitude,
          'long': longitude,
        },
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

      // if (!response.success || response.data == null) {
      if (response.data == null) {
        throw ApiError(
          message: response.message ?? 'Failed to fetch nearest branches',
        );
      }

      debugPrint("Nearest branches response: ${response.toString()}");
      return response.data!;
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError(
        message: 'Error fetching nearest branches: $e',
        originalError: e,
      );
    }
  }

  /// Get nearest branches within radius
  Future<List<Shift>> getShift() async {
    try {
      final response = await _apiService.get<List<Shift>>(
        '/attendances/shift',
        queryParameters: {},
        dataParser: (json) {
          if (json is List) {
            // debugPrint("Parsing shift: $json");
            return (json)
                .map((item) => Shift.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          // debugPrint("LOLOS");
          return [];
        },
      );

      // if (!response.success || response.data == null) {
      if (response.data == null) {
        throw ApiError(
          message: response.message ?? 'Failed to fetch shift',
        );
      }

      // debugPrint("Shift response: ${response.toString()}");
      return response.data!;
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError(
        message: 'Error fetching shift: $e',
        originalError: e,
      );
    }
  }
}
