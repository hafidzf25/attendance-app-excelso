/// API error model untuk standardisasi error handling
class ApiError implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final dynamic originalError;

  ApiError({
    required this.message,
    this.code,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;

  /// User-friendly error message
  String getUserMessage() {
    if (statusCode == 401) return 'Sesi Anda telah berakhir. Silakan login kembali.';
    if (statusCode == 403) return 'Anda tidak memiliki izin untuk aksi ini.';
    if (statusCode == 404) return 'Data tidak ditemukan.';
    if (statusCode == 409) return 'Terjadi konflik data. Silakan coba lagi.';
    if (statusCode == 422) return 'Data yang Anda kirim tidak valid.';
    if (statusCode == 429) return 'Terlalu banyak permintaan. Silakan tunggu sebentar.';
    if (statusCode == 500) return 'Terjadi kesalahan di server. Silakan coba lagi nanti.';
    if (statusCode == 503) return 'Server sedang dalam pemeliharaan. Silakan coba lagi nanti.';
    
    // Default messages untuk nomor network
    if (message.contains('SocketException')) return 'Tidak ada koneksi internet.';
    if (message.contains('TimeoutException')) return 'Permintaan timeout. Silakan coba lagi.';
    
    return message;
  }
}
