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
