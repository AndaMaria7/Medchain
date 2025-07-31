class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;
  final DateTime timestamp;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.statusCode,
    required this.timestamp,
  });

  factory ApiResponse.success({
    required T data,
    String? message,
    int? statusCode,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
      timestamp: DateTime.now(),
    );
  }

  factory ApiResponse.error({
    required String error,
    String? message,
    int? statusCode,
  }) {
    return ApiResponse(
      success: false,
      error: error,
      message: message,
      statusCode: statusCode,
      timestamp: DateTime.now(),
    );
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'],
      message: json['message'],
      error: json['error'],
      statusCode: json['statusCode'] ?? json['status_code'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'message': message,
      'error': error,
      'statusCode': statusCode,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isSuccess => success && error == null;
  bool get isError => !success || error != null;

  @override
  String toString() {
    return 'ApiResponse(success: $success, data: $data, error: $error)';
  }
}