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

/// Temp Attendance Identify model
class AttendanceIdentify {
  final String? employeeId;
  final String? employeeNumber;
  final String? employeeName;
  final String? type;
  final String? tempImagePath;
  final String? token;

  AttendanceIdentify({
    this.employeeId,
    this.employeeNumber,
    this.employeeName,
    this.type,
    this.tempImagePath,
    this.token,
  });

  /// Convert ke JSON untuk API
  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeNumber': employeeNumber,
      'type': type,
      'tempImagePath': tempImagePath,
      'token': token,
    };
  }

  /// Parse dari API response
  factory AttendanceIdentify.fromJson(Map<String, dynamic> json) {
    return AttendanceIdentify(
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      employeeNumber: json['employeeNumber'] as String,
      type: json['type'] as String,
      tempImagePath: json['tempImagePath'] as String,
      token: json['token'] as String,
    );
  }
}

/// Temp Attendance Identify model
class EnrollData {
  final String? employeeNumber;
  final String? employeeName;
  final int? faceEmbeddingCount;
  final int? maxFaceEmbeddings;

  EnrollData(
      {this.employeeNumber,
      this.employeeName,
      this.faceEmbeddingCount,
      this.maxFaceEmbeddings});

  /// Convert ke JSON untuk API
  Map<String, dynamic> toJson() {
    return {
      'employeeName': employeeName,
      'employeeNumber': employeeNumber,
      'faceEmbeddingCount': faceEmbeddingCount,
      'maxFaceEmbeddings': maxFaceEmbeddings,
    };
  }

  /// Parse dari API response
  factory EnrollData.fromJson(Map<String, dynamic> json) {
    return EnrollData(
      employeeName: json['employeeName'] as String,
      employeeNumber: json['employeeNumber'] as String,
      faceEmbeddingCount: json['faceEmbeddingCount'] as int,
      maxFaceEmbeddings: json['maxFaceEmbeddings'] as int,
    );
  }
}

/// Attendance repository - centralize semua attendance API calls
class AttendanceRepository {
  final ApiService _apiService = ApiService();

  /// Identify user before accept attendance
  Future<AttendanceIdentify> identify({
    required String photoPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          photoPath,
          filename: 'attendance.jpg',
        ),
      });

      final response = await _apiService.post<AttendanceIdentify>(
        '/attendances/identify',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        dataParser: (json) =>
            AttendanceIdentify.fromJson(json as Map<String, dynamic>),
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

  /// Confirm attendance after identify
  Future<Map<String, dynamic>> confirmAttendance({
    required String token,
    required double latitude,
    required double longitude,
    int? shiftId,
    required String branchCode,
    required String type,
  }) async {
    try {
      Map<String, dynamic> bodyData = {};
      if (type == 'in') {
        bodyData = {
          'token': token,
          'latitude': latitude,
          'longitude': longitude,
          'shiftId': shiftId,
          'branchCode': branchCode,
        };
      } else {
        bodyData = {
          'token': token,
          'latitude': latitude,
          'longitude': longitude,
          'branchCode': branchCode,
        };
      }

      final response = await _apiService.post(
        '/attendances',
        data: bodyData,
        options: Options(contentType: 'application/json'),
        dataParser: (json) => json as Map<String, dynamic>,
      );

      debugPrint("Check response: ${response.data}");

      // if (!response.success || response.data == null) {
      if (response.data == null) {
        throw ApiError(
          message: response.message ?? 'Confirm attendance failed',
        );
      }

      // return response.message ?? 'Check-in successful'; // dummy, karena API belum siap, kita return message dulu
      debugPrint("Hasil response confirm ${response.data}");
      return response.data!; // rill
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError(
        message: 'Error during confirm attendance: $e',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> enrollFace({
    required String photoPath,
    required String employeeNumber,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          photoPath,
          filename: 'attendance.jpg',
        ),
        'employeeNumber': employeeNumber,
      });

      final response = await _apiService.post(
        '/attendances/enroll',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        dataParser: (json) => json as Map<String, dynamic>,
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

  /// Get nearest branches within radius
  Future<EnrollData> getEnroll({
    required String employeeNumber,
  }) async {
    try {
      final response = await _apiService.get<EnrollData>(
        '/attendances/enroll/$employeeNumber',
        queryParameters: {},
        dataParser: (json) => EnrollData.fromJson(json as Map<String, dynamic>),
      );

      // if (!response.success || response.data == null) {
      if (response.data == null) {
        throw ApiError(
          message: response.message ?? 'Failed to fetch data enroll employee',
        );
      }

      // debugPrint("Shift response: ${response.toString()}");
      return response.data!;
    } on ApiError {
      rethrow;
    } catch (e) {
      throw ApiError(
        message: 'Error fetching data enroll employee: $e',
        originalError: e,
      );
    }
  }

  // /// Submit attendance check-in
  // Future<AttendanceRecord> checkIn({
  //   required String photoPath,
  //   required double latitude,
  //   required double longitude,
  //   required String type,
  //   required int? shiftId,
  //   required String branchCode,
  // }) async {
  //   try {
  //     final formData = FormData.fromMap({
  //       'file': await MultipartFile.fromFile(
  //         photoPath,
  //         filename: 'attendance.jpg',
  //       ),
  //       'latitude': latitude,
  //       'longitude': longitude,
  //       'type': type,
  //       'shiftId': shiftId,
  //       'branchCode': branchCode,
  //     });

  //     final response = await _apiService.post<AttendanceRecord>(
  //       '/attendances',
  //       data: formData,
  //       options: Options(contentType: 'multipart/form-data'),
  //       dataParser: (json) =>
  //           AttendanceRecord.fromJson(json as Map<String, dynamic>),
  //     );

  //     debugPrint("Checkin response: ${response.toString()}");

  //     // if (!response.success || response.data == null) {
  //     if (response.data == null) {
  //       throw ApiError(
  //         message: response.message ?? 'Check-in failed',
  //       );
  //     }

  //     // return response.message ?? 'Check-in successful'; // dummy, karena API belum siap, kita return message dulu
  //     debugPrint("${response.rawData}");
  //     return response.data!; // rill
  //   } on ApiError {
  //     rethrow;
  //   } catch (e) {
  //     throw ApiError(
  //       message: 'Error during check-in: $e',
  //       originalError: e,
  //     );
  //   }
  // }

  // /// Submit attendance check-out
  // Future<AttendanceRecord> checkOut({
  //   required String photoPath,
  //   required double latitude,
  //   required double longitude,
  //   required String type,
  //   required String branchCode,
  // }) async {
  //   try {
  //     final formData = FormData.fromMap({
  //       'file': await MultipartFile.fromFile(
  //         photoPath,
  //         filename: 'attendance.jpg',
  //       ),
  //       'latitude': latitude,
  //       'longitude': longitude,
  //       'type': type,
  //       'branchCode': branchCode,
  //     });

  //     final response = await _apiService.post<AttendanceRecord>(
  //       '/attendances',
  //       data: formData,
  //       options: Options(contentType: 'multipart/form-data'),
  //       dataParser: (json) =>
  //           AttendanceRecord.fromJson(json as Map<String, dynamic>),
  //     );

  //     debugPrint("Checkin response: ${response.toString()}");

  //     // if (!response.success || response.data == null) {
  //     if (response.data == null) {
  //       throw ApiError(
  //         message: response.message ?? 'Check-in failed',
  //       );
  //     }

  //     // return response.message ?? 'Check-in successful'; // dummy, karena API belum siap, kita return message dulu
  //     debugPrint("${response.rawData}");
  //     return response.data!; // rill
  //   } on ApiError {
  //     rethrow;
  //   } catch (e) {
  //     throw ApiError(
  //       message: 'Error during check-in: $e',
  //       originalError: e,
  //     );
  //   }
  // }

  // /// Get today's attendance
  // Future<AttendanceRecord?> getTodayAttendance({
  //   required String userId,
  // }) async {
  //   try {
  //     final response = await _apiService.get<AttendanceRecord>(
  //       '/attendance/today',
  //       queryParameters: {'user_id': userId},
  //       dataParser: (json) =>
  //           AttendanceRecord.fromJson(json as Map<String, dynamic>),
  //     );

  //     if (!response.success) {
  //       debugPrint('Error: ${response.message}');
  //       return null;
  //     }

  //     return response.data;
  //   } on ApiError catch (e) {
  //     debugPrint('Error getting today attendance: ${e.message}');
  //     rethrow;
  //   }
  // }
}
