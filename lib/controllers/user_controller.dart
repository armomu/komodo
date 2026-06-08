import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:komodo/config/base_url.dart';
import 'package:komodo/models/user.dart';
import 'package:komodo/pages/message/controllers/consumer_list_controller.dart';
import 'package:komodo/utils/request.dart';
import 'package:komodo/pages/message/controllers/consumer_ws_client.dart';

/// 全局用户状态控制器
/// 管理登录/登出、token 持久化、用户信息、注册等。
/// 通过 GetX 响应式驱动 UI 更新。
class UserController extends GetxController {
  static UserController get to => Get.find();

  // ============ 响应式状态 ============

  /// 是否已登录
  final isLogin = false.obs;
  bool get isLoggedIn => isLogin.value;

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

  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'user_email';
  static const String _nicknameKey = 'user_nickname';
  static const String _avatarKey = 'user_avatar';

  // ----------- 记住密码相关 key -----------
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';
  static const String _rememberMeKey = 'remember_me';

  // ============ 生命周期 ============

  @override
  void onInit() {
    super.onInit();
    getProfile();
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
    box.write(BaseUrl.tokenKey, token);
    box.write(_userIdKey, id);
    box.write(_emailKey, email);
    box.write(_nicknameKey, nickname);
    box.write(_avatarKey, avatar);
  }

  /// 清除本地存储的用户信息
  void _clearSavedUserInfo() {
    final box = GetStorage();
    box.remove(BaseUrl.tokenKey);
    box.remove(_userIdKey);
    box.remove(_emailKey);
    box.remove(_nicknameKey);
    box.remove(_avatarKey);
  }

  // ============ 记住密码 ============

  /// 读取已保存的登录凭据，返回 {email, password, rememberMe}
  Map<String, dynamic> loadSavedCredentials() {
    final box = GetStorage();
    return {
      'email': box.read<String>(_savedEmailKey) ?? '',
      'password': box.read<String>(_savedPasswordKey) ?? '',
      'rememberMe': box.read<bool>(_rememberMeKey) ?? false,
    };
  }

  /// 保存登录凭据（勾选"记住密码"时调用）
  void saveCredentials(String email, String password) {
    final box = GetStorage();
    box.write(_savedEmailKey, email);
    box.write(_savedPasswordKey, password);
    box.write(_rememberMeKey, true);
  }

  /// 清除保存的登录凭据（取消勾选或主动注销时调用）
  void clearCredentials() {
    final box = GetStorage();
    box.remove(_savedEmailKey);
    box.remove(_savedPasswordKey);
    box.write(_rememberMeKey, false);
  }

  // ============ 业务方法 ============

  /// 登录
  Future<bool> login(String email, String password) async {
    _loading.value = true;
    _errorMessage.value = '';

    try {
      final response = await appDio<LoginResult>(
        '/consumer/auth/login',
        method: 'post',
        data: {'email': email, 'password': password},
        fromJsonT: (data) => LoginResult.fromJson(data as Map<String, dynamic>),
      );

      _loading.value = false;

      if (response.isSuccess && response.data != null) {
        final result = response.data!;
        // 保存到内存
        _accessToken.value = result.accessToken;
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

        isLogin.value = true;
        // 连接 WebSocket
        _connectWs();

        return true;
      } else {
        _errorMessage.value = response.message;
        return false;
      }
    } catch (e) {
      _loading.value = false;
      _errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  /// 注册
  Future<bool> register(String email, String code, String password) async {
    _loading.value = true;
    _errorMessage.value = '';

    try {
      final response = await appDio<Map<String, dynamic>>(
        '/consumer/auth/register',
        method: 'post',
        data: {'email': email, 'code': code, 'password': password},
      );

      _loading.value = false;

      if (response.isSuccess) {
        // 注册成功后自动登录，记录用户信息但不需要存储 token
        final data = response.data;
        if (data != null) {
          isLogin.value = true;
          _userId.value = data['id'] as int? ?? 0;
          _email.value = data['email'] as String? ?? email;
          _nickname.value =
              data['nickname'] as String? ?? email.split('@').first;
          _avatar.value = data['avatar'] as String? ?? '';

          // 注册接口返回没有 accessToken，所以不清除已有 token，也不自动登录
          // 注册完成后提示用户去登录
        }
        return true;
      } else {
        _errorMessage.value = response.message;
        return false;
      }
    } catch (e) {
      _loading.value = false;
      _errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  /// 发送邮箱验证码
  Future<bool> sendCaptcha(String email) async {
    _loading.value = true;
    _errorMessage.value = '';

    try {
      final response = await appDio<Map<String, dynamic>>(
        '/auth/mail/captcha',
        method: 'get',
        params: {'email': email},
      );

      _loading.value = false;

      if (response.isSuccess) {
        return true;
      } else {
        _errorMessage.value = response.message;
        return false;
      }
    } catch (e) {
      _loading.value = false;
      _errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  /// 更新用户资料（头像和/或昵称）
  Future<bool> updateProfile({String? nickname, String? avatar}) async {
    _loading.value = true;
    _errorMessage.value = '';

    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (avatar != null) body['avatar'] = avatar;

    try {
      final response = await appDio<UserProfile>(
        '/consumer/auth/profile',
        method: 'patch',
        data: body,
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
    } catch (e) {
      _loading.value = false;
      _errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  /// 获取用户资料
  Future<bool> getProfile() async {
    _loading.value = true;
    _errorMessage.value = '';

    final box = GetStorage();
    final token = box.read<String>(BaseUrl.tokenKey) ?? '';
    if (token.isEmpty) {
      _loading.value = false;
      return false;
    }
    try {
      final response = await appDio<UserProfile>(
        '/consumer/auth/profile',
        method: 'get',
        fromJsonT: (data) => UserProfile.fromJson(data as Map<String, dynamic>),
      );

      _loading.value = false;
      if (response.isSuccess && response.data != null) {
        final profile = response.data!;
        // 更新本地状态
        _nickname.value = profile.nickname;
        _avatar.value = profile.avatar;

        isLogin.value = true;
        _userId.value = profile.id;
        _email.value = profile.email;
        _connectWs();
        // 持久化更新
        final box = GetStorage();
        box.write(_nicknameKey, profile.nickname);
        box.write(_avatarKey, profile.avatar);
        final token = box.read<String>(BaseUrl.tokenKey) ?? '';
        _accessToken.value = token;
        Get.find<ConsumerListController>().refreshList();
        return true;
      } else {
        _errorMessage.value = response.message;
        return false;
      }
    } catch (e) {
      _loading.value = false;
      // getProfile 在 onInit 中调用，token 未登录时 401 会抛异常，静默处理
      _errorMessage.value = '';
      return false;
    }
  }

  /// 登出（调用服务端 + 清除本地状态 + 断开 WebSocket）
  Future<bool> logout() async {
    _loading.value = true;

    // 断开 WebSocket
    if (Get.isRegistered<ConsumerWsClient>()) {
      Get.find<ConsumerWsClient>().disconnect();
    }

    // 调用服务端注销
    try {
      final response = await appDio<dynamic>(
        '/consumer/auth/logout',
        method: 'post',
      );
      clearLoginState();
      return response.isSuccess;
    } catch (e) {
      // 即使服务端报错，也清除本地状态
      clearLoginState();
      return false;
    }
  }

  void clearLoginState() {
    _loading.value = false;

    // 无论服务端结果如何，都清除本地状态
    _accessToken.value = '';
    isLogin.value = false;
    _userId.value = 0;
    _email.value = '';
    _nickname.value = '';
    _avatar.value = '';
    _errorMessage.value = '';

    _clearSavedUserInfo();
  }

  /// 连接 WebSocket（使用当前 token）
  void _connectWs() {
    Get.find<ConsumerWsClient>().connect().catchError((_) {});
  }
}
