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

/// 登录接口返回的 data 模型
class LoginResult {
  final String accessToken;
  final int id;
  final String email;
  final String nickname;
  final String avatar;

  const LoginResult({
    required this.accessToken,
    required this.id,
    required this.email,
    required this.nickname,
    required this.avatar,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      accessToken: json['accessToken'] as String? ?? '',
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'id': id,
        'email': email,
        'nickname': nickname,
        'avatar': avatar,
      };
}

/// 用户资料模型（用于 PATCH profile 响应和本地持久化）
class UserProfile {
  final int id;
  final String email;
  final String nickname;
  final String avatar;
  final bool enable;
  final String? createTime;
  final String? updateTime;

  const UserProfile({
    required this.id,
    required this.email,
    required this.nickname,
    required this.avatar,
    this.enable = true,
    this.createTime,
    this.updateTime,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      enable: json['enable'] as bool? ?? true,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nickname': nickname,
        'avatar': avatar,
        'enable': enable,
        'createTime': createTime,
        'updateTime': updateTime,
      };
}
