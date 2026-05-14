import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:komodo/models/api_response.dart';
import 'package:komodo/services/api_service.dart';

/// 全局用户状态控制器
/// 管理登录/登出、token 持久化、用户信息、注册等。
/// 通过 GetX 响应式驱动 UI 更新。
class UserController extends GetxController {
  static UserController get to => Get.find();

  final ApiService _apiService = ApiService.to;

  // ============ 响应式状态 ============

  /// 是否已登录
  final _isLoggedIn = false.obs;
  bool get isLoggedIn => _isLoggedIn.value;

  /// 登录 token
  final _accessToken = ''.obs;
  String get accessToken => _accessToken.value;

  /// 用户信息
  final _userId = 0.obs;
  final _email = ''.obs;
  final _nickname = ''.obs;
  final _avatar = ''.obs;

  int get userId => _userId.value;
  String get email => _email.value;
  String get nickname => _nickname.value;
  String get avatar => _avatar.value;

  /// 请求加载中
  final _loading = false.obs;
  bool get loading => _loading.value;

  /// 错误消息
  final _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  // ============ 本地存储 key ============
  static const String _tokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'user_email';
  static const String _nicknameKey = 'user_nickname';
  static const String _avatarKey = 'user_avatar';

  // ============ 生命周期 ============

  @override
  void onInit() {
    super.onInit();
    _loadSavedUserInfo();
  }

  /// 启动时从本地加载已保存的用户信息
  void _loadSavedUserInfo() {
    final box = GetStorage();
    final token = box.read<String>(_tokenKey) ?? '';
    if (token.isNotEmpty) {
      _accessToken.value = token;
      _isLoggedIn.value = true;
      _userId.value = box.read<int>(_userIdKey) ?? 0;
      _email.value = box.read<String>(_emailKey) ?? '';
      _nickname.value = box.read<String>(_nicknameKey) ?? '';
      _avatar.value = box.read<String>(_avatarKey) ?? '';
    }
  }

  /// 保存用户信息到本地存储
  void _saveUserInfo({
    required String token,
    required int id,
    required String email,
    required String nickname,
    required String avatar,
  }) {
    final box = GetStorage();
    box.write(_tokenKey, token);
    box.write(_userIdKey, id);
    box.write(_emailKey, email);
    box.write(_nicknameKey, nickname);
    box.write(_avatarKey, avatar);
  }

  /// 清除本地存储的用户信息
  void _clearSavedUserInfo() {
    final box = GetStorage();
    box.remove(_tokenKey);
    box.remove(_userIdKey);
    box.remove(_emailKey);
    box.remove(_nicknameKey);
    box.remove(_avatarKey);
  }

  // ============ 业务方法 ============

  /// 登录
  Future<bool> login(String email, String password) async {
    _loading.value = true;
    _errorMessage.value = '';

    final response = await _apiService.post<LoginResult>(
      '/consumer/auth/login',
      body: {'email': email, 'password': password},
      fromJsonT: (data) => LoginResult.fromJson(data as Map<String, dynamic>),
    );

    _loading.value = false;

    if (response.isSuccess && response.data != null) {
      final result = response.data!;
      // 保存到内存
      _accessToken.value = result.accessToken;
      _isLoggedIn.value = true;
      _userId.value = result.id;
      _email.value = result.email;
      _nickname.value = result.nickname;
      _avatar.value = result.avatar;

      // 持久化到本地
      _saveUserInfo(
        token: result.accessToken,
        id: result.id,
        email: result.email,
        nickname: result.nickname,
        avatar: result.avatar,
      );

      return true;
    } else {
      _errorMessage.value = response.message;
      return false;
    }
  }

  /// 注册
  Future<bool> register(String email, String code, String password) async {
    _loading.value = true;
    _errorMessage.value = '';

    final response = await _apiService.post<Map<String, dynamic>>(
      '/consumer/auth/register',
      body: {'email': email, 'code': code, 'password': password},
    );

    _loading.value = false;

    if (response.isSuccess) {
      // 注册成功后自动登录，记录用户信息但不需要存储 token
      final data = response.data;
      if (data != null) {
        _isLoggedIn.value = true;
        _userId.value = data['id'] as int? ?? 0;
        _email.value = data['email'] as String? ?? email;
        _nickname.value = data['nickname'] as String? ?? email.split('@').first;
        _avatar.value = data['avatar'] as String? ?? '';

        // 注册接口返回没有 accessToken，所以不清除已有 token，也不自动登录
        // 注册完成后提示用户去登录
      }
      return true;
    } else {
      _errorMessage.value = response.message;
      return false;
    }
  }

  /// 发送邮箱验证码
  Future<bool> sendCaptcha(String email) async {
    _loading.value = true;
    _errorMessage.value = '';

    final response = await _apiService.get<Map<String, dynamic>>(
      '/auth/mail/captcha',
      query: {'email': email},
    );

    _loading.value = false;

    if (response.isSuccess) {
      return true;
    } else {
      _errorMessage.value = response.message;
      return false;
    }
  }

  /// 更新用户资料（头像和/或昵称）
  Future<bool> updateProfile({
    String? nickname,
    String? avatar,
  }) async {
    _loading.value = true;
    _errorMessage.value = '';

    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (avatar != null) body['avatar'] = avatar;

    final response = await _apiService.patch<UserProfile>(
      '/consumer/auth/profile',
      body: body,
      fromJsonT: (data) => UserProfile.fromJson(data as Map<String, dynamic>),
    );

    _loading.value = false;

    if (response.isSuccess && response.data != null) {
      final profile = response.data!;
      // 更新本地状态
      _nickname.value = profile.nickname;
      _avatar.value = profile.avatar;

      // 持久化更新
      final box = GetStorage();
      box.write(_nicknameKey, profile.nickname);
      box.write(_avatarKey, profile.avatar);

      return true;
    } else {
      _errorMessage.value = response.message;
      return false;
    }
  }

  /// 登出（调用服务端 + 清除本地状态）
  Future<bool> logout() async {
    _loading.value = true;

    // 调用服务端注销
    final response = await _apiService.post<dynamic>(
      '/consumer/auth/logout',
    );

    _loading.value = false;

    // 无论服务端结果如何，都清除本地状态
    _accessToken.value = '';
    _isLoggedIn.value = false;
    _userId.value = 0;
    _email.value = '';
    _nickname.value = '';
    _avatar.value = '';
    _errorMessage.value = '';

    _clearSavedUserInfo();

    return response.isSuccess;
  }
}
