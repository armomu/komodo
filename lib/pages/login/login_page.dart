import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/controllers/user_controller.dart';
import 'package:komodo/routes/app_routes.dart';

/// 登录页面
/// 简单的用户名密码登录表单
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userController = Get.find<UserController>();

  /// 是否显示密码
  final _obscurePassword = true.obs;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _userController.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      Get.offAllNamed(Routes.home);
    } else {
      if (mounted) {
        Get.snackbar(
          '登录失败',
          _userController.errorMessage.isNotEmpty
              ? _userController.errorMessage
              : '请检查用户名和密码',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade700,
          icon: const Icon(Icons.error_outline, color: Colors.red),
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / 标题
                  Icon(
                    Icons.music_note_rounded,
                    size: 80,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'KOMODO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '登录以继续使用',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 用户名输入框
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: '用户名',
                      hintText: '请输入用户名',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入用户名';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 密码输入框
                  Obx(
                    () => TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword.value,
                      decoration: InputDecoration(
                        labelText: '密码',
                        hintText: '请输入密码',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              _obscurePassword.toggle(),
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入密码';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 登录按钮
                  Obx(
                    () => SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            _userController.loading ? null : _handleLogin,
                        child: _userController.loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('登 录', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
