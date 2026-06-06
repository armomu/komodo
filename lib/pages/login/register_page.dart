import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/controllers/user_controller.dart';
import 'package:komodo/routes/app_routes.dart';

/// 注册页面
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _userController = Get.find<UserController>();

  /// 密码可见性
  final _obscurePassword = true.obs;
  final _obscureConfirm = true.obs;

  /// 验证码倒计时
  final _countdown = 0.obs;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// 发送验证码
  Future<void> _handleSendCaptcha() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      Get.snackbar(
        '提示',
        '请先输入有效的邮箱地址',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final success = await _userController.sendCaptcha(email);
    if (success) {
      Get.snackbar(
        '验证码已发送',
        '请检查您的邮箱',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade700,
        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
      );
      // 开始倒计时
      _startCountdown();
    } else {
      if (mounted) {
        Get.snackbar(
          '发送失败',
          _userController.errorMessage.isNotEmpty
              ? _userController.errorMessage
              : '验证码发送失败，请稍后重试',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade700,
          icon: const Icon(Icons.error_outline, color: Colors.red),
        );
      }
    }
  }

  void _startCountdown() {
    _countdown.value = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown.value <= 1) {
        timer.cancel();
        _countdown.value = 0;
      } else {
        _countdown.value--;
      }
    });
  }

  /// 提交注册
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _userController.register(
      _emailController.text.trim(),
      _codeController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      if (mounted) {
        Get.snackbar(
          '注册成功',
          '请使用注册的邮箱登录',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade700,
          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
          duration: const Duration(seconds: 2),
        );
        // 跳转到登录页
        Get.offNamed(Routes.login);
      }
    } else {
      if (mounted) {
        Get.snackbar(
          '注册失败',
          _userController.errorMessage.isNotEmpty
              ? _userController.errorMessage
              : '注册失败，请稍后重试',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade700,
          icon: const Icon(Icons.error_outline, color: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('注册'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
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
                  // 标题
                  Text(
                    '创建账号',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '注册后即可享受完整功能',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // 邮箱输入框
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '邮箱',
                      hintText: '请输入邮箱',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入邮箱';
                      }
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(value.trim())) {
                        return '请输入有效的邮箱地址';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 验证码输入框
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '验证码',
                      hintText: '请输入验证码',
                      prefixIcon: const Icon(Icons.sms_outlined),
                      suffixIcon: Obx(
                        () => SizedBox(
                          width: 100,
                          child: TextButton(
                            onPressed: _countdown.value > 0
                                ? null
                                : _handleSendCaptcha,
                            child: _countdown.value > 0
                                ? Text(
                                    '${_countdown.value}s',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withAlpha(100),
                                      fontSize: 13,
                                    ),
                                  )
                                : const Text(
                                    '获取验证码',
                                    style: TextStyle(fontSize: 13),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入验证码';
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
                        hintText: '6-20个字符',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => _obscurePassword.toggle(),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入密码';
                        }
                        if (value.length < 6 || value.length > 20) {
                          return '密码长度需在6-20个字符之间';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 确认密码输入框
                  Obx(
                    () => TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm.value,
                      decoration: InputDecoration(
                        labelText: '确认密码',
                        hintText: '再次输入密码',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => _obscureConfirm.toggle(),
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleRegister(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请再次输入密码';
                        }
                        if (value != _passwordController.text) {
                          return '两次密码不一致';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 注册按钮
                  Obx(
                    () => SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            _userController.loading ? null : _handleRegister,
                        child: _userController.loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('注 册', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '已有账号？',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withAlpha(120),
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Text(
                          '去登录',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
