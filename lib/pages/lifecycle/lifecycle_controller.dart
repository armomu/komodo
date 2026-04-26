import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 生命周期控制器 - 使用 GetX 管理状态
class LifecycleController extends GetxController {
  static LifecycleController get to => Get.find();

  // ==================== 状态变量 ====================
  
  /// 是否显示子组件
  final showChildWidget = true.obs;
  
  /// 父组件标题
  final parentTitle = '父组件标题'.obs;
  
  /// 日志列表
  final logs = <String>[].obs;

  // ==================== 计算属性 ====================
  
  /// 日志数量
  int get logCount => logs.length;
  
  /// 是否为空日志
  bool get isEmptyLogs => logs.isEmpty;

  // ==================== 方法 ====================
  
  /// 切换子组件显示状态
  void toggleChildWidget() {
    showChildWidget.value = !showChildWidget.value;
    addLog(showChildWidget.value ? '👁️ 显示子组件' : '🙈 隐藏子组件');
  }

  /// 切换父组件标题
  void toggleParentTitle() {
    parentTitle.value = parentTitle.value == '父组件标题' 
        ? '更新后的标题' 
        : '父组件标题';
    addLog('📝 父组件标题已更新: ${parentTitle.value}');
  }

  /// 添加日志
  void addLog(String message) {
    final String timeLog = 
        '${DateTime.now().toString().substring(11, 19)} - $message';
    
    // 使用 addPostFrameCallback 确保不在 build 过程中更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logs.insert(0, timeLog);
      if (logs.length > 50) {
        logs.removeLast();
      }
    });
    
    debugPrint('🔵 [生命周期] $message');
  }

  /// 清空日志
  void clearLogs() {
    logs.clear();
    // 直接添加日志，不通过 addLog 避免 addPostFrameCallback 延迟
    final String timeLog = 
        '${DateTime.now().toString().substring(11, 19)} - 🗑️ 日志已清空';
    logs.insert(0, timeLog);
    debugPrint('🔵 [生命周期] 🗑️ 日志已清空');
  }

  // ==================== 生命周期钩子 ====================
  
  @override
  void onInit() {
    super.onInit();
    debugPrint('🚀 LifecycleController onInit');
    // onInit 中不能调用 addLog，因为 Get.find 会触发递归
    // 日志将在 onReady 中添加
  }

  @override
  void onReady() {
    super.onReady();
    debugPrint('✅ LifecycleController onReady');
    addLog('✅ Controller 准备就绪');
  }

  @override
  void onClose() {
    debugPrint('🗑️ LifecycleController onClose');
    super.onClose();
  }
}
