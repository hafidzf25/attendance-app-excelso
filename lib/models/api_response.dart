/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final dynamic rawData; // Raw response untuk debugging

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.rawData,
  });

  /// Parse dari JSON response
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  ) {
    try {
      final success = json['success'] ?? json['status'] == 'success';
      final data = dataParser != null && json['data'] != null
          ? dataParser(json['data'])
          : null;

      return ApiResponse(
        success: success,
        message: json['message'] ?? json['error'],
        data: data,
        rawData: json,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error parsing response: $e',
        rawData: json,
      );
    }
  }

  @override
  String toString() =>
      'ApiResponse(success: $success, message: $message, data: $data)';
}
