import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:komodo/models/api_response.dart';
import 'package:komodo/services/api_service.dart';

/// 全局用户状态控制器
/// 管理登录/登出、token 持久化、登录状态等。
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

  /// 请求加载中
  final _loading = false.obs;
  bool get loading => _loading.value;

  /// 错误消息
  final _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  // ============ 生命周期 ============

  @override
  void onInit() {
    super.onInit();
    _loadSavedToken();
  }

  /// 启动时从本地加载已保存的 token
  void _loadSavedToken() {
    final box = GetStorage();
    final token = box.read<String>('access_token') ?? '';
    if (token.isNotEmpty) {
      _accessToken.value = token;
      _isLoggedIn.value = true;
    }
  }

  // ============ 业务方法 ============

  /// 登录
  /// [username] 用户名
  /// [password] 密码
  /// 返回是否登录成功
  Future<bool> login(String username, String password) async {
    _loading.value = true;
    _errorMessage.value = '';

    final response = await _apiService.post<LoginResult>(
      '/auth/login',
      body: {'username': username, 'password': password},
      fromJsonT: (data) => LoginResult.fromJson(data as Map<String, dynamic>),
    );

    _loading.value = false;

    if (response.isSuccess && response.data != null) {
      // 保存 token 到内存
      _accessToken.value = response.data!.accessToken;
      _isLoggedIn.value = true;

      // 持久化 token 到本地
      _apiService.saveToken(response.data!.accessToken);

      return true;
    } else {
      _errorMessage.value = response.message;
      return false;
    }
  }

  /// 登出
  void logout() {
    _accessToken.value = '';
    _isLoggedIn.value = false;
    _errorMessage.value = '';

    // 清除本地 token
    _apiService.clearToken();
  }
}
