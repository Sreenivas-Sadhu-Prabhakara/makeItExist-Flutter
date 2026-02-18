class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';

  factory ApiException.fromDioError(dynamic error) {
    if (error.response != null) {
      final data = error.response?.data;
      final message = data is Map ? (data['message'] ?? 'Unknown error') : 'Unknown error';
      return ApiException(
        message: message,
        statusCode: error.response?.statusCode,
        data: data,
      );
    }
    return ApiException(
      message: error.message ?? 'Network error occurred',
    );
  }
}
