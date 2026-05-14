import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komodo/controllers/user_controller.dart';
import 'package:komodo/utils/avatar_data.dart';

/// 编辑资料页面
/// 可修改昵称和头像（从8个在线头像中选择）
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _userController = Get.find<UserController>();
  late final TextEditingController _nicknameController;
  late String _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: _userController.nickname,
    );
    _selectedAvatar = _userController.avatar;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      Get.snackbar(
        '提示',
        '昵称不能为空',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    if (nickname.length > 50) {
      Get.snackbar(
        '提示',
        '昵称最长50个字符',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final success = await _userController.updateProfile(
      nickname: nickname,
      avatar: _selectedAvatar,
    );

    if (success) {
      if (mounted) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          Get.snackbar(
            '保存成功',
            '资料已更新',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade50,
            colorText: Colors.green.shade700,
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            duration: const Duration(seconds: 2),
          );
        }
      }
    } else {
      if (mounted) {
        Get.snackbar(
          '保存失败',
          _userController.errorMessage.isNotEmpty
              ? _userController.errorMessage
              : '请稍后重试',
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑资料'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(
            () => TextButton(
              onPressed: _userController.loading ? null : _handleSave,
              child: _userController.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ============ 当前头像预览 ============
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withAlpha(60),
                  width: 3,
                ),
                image: _selectedAvatar.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_selectedAvatar),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: _selectedAvatar.isEmpty
                    ? colorScheme.surfaceContainerHighest
                    : null,
              ),
              child: _selectedAvatar.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 50,
                      color: colorScheme.onSurfaceVariant,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '选择头像',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ============ 昵称编辑 ============
          Text(
            '昵称',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameController,
            decoration: InputDecoration(
              hintText: '请输入昵称',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            textInputAction: TextInputAction.done,
            maxLength: 50,
          ),

          const SizedBox(height: 32),

          // ============ 头像选择 ============
          Text(
            '选择头像',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: avatarUrls.length,
            itemBuilder: (context, index) {
              final url = avatarUrls[index];
              final isSelected = _selectedAvatar == url;
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = url),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withAlpha(50),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                    image: DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: isSelected
                      ? Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.check,
                              size: 14,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
