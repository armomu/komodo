/// 通用 API 响应模型
/// 对应后端统一响应格式：
/// {
///   "code": 0,
///   "message": "OK",
///   "data": { ... }
/// }
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final String? originUrl;

  const ApiResponse({
    required this.code,
    required this.message,
    this.data,
    this.originUrl,
  });

  /// 请求是否成功（code == 0）
  bool get isSuccess => code == 0;

  /// 构造一个错误响应
  factory ApiResponse.error(int code, String message) {
    return ApiResponse(code: code, message: message);
  }

  /// 从 JSON 构造，需提供 data 的转换函数 [fromJsonT]
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse(
      code: json['code'] as int? ?? -1,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      originUrl: json['originUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic>? Function(T?)? toJsonT) {
    return {
      'code': code,
      'message': message,
      'data': toJsonT != null ? toJsonT(data) : data,
      'originUrl': originUrl,
    };
  }

  @override
  String toString() =>
      'ApiResponse(code: $code, message: $message, data: $data)';
}
